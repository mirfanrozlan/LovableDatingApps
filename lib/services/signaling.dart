import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302'],
      },
      {
        'urls': [
          'turn:turn.mazri-minecraft.xyz:3478?transport=udp',
          'turn:turn.mazri-minecraft.xyz:3478?transport=tcp',
        ],
        'username': 'mazri',
        'credential': 'Azri19112002!',
      },
    ],
    'iceTransportPolicy': 'all',
    'sdpSemantics': 'unified-plan',
  };

  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  MediaStream? LocalStream;
  MediaStream? RemoteStream;
  String? roomId;
  String? currentRoomText;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  void Function(RTCPeerConnectionState state)? onPeerConnectionState;
  void Function(RTCIceConnectionState state)? onIceConnectionState;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  int _localIceCount = 0;
  int _remoteIceCount = 0;
  bool enableIceBatching = false;
  bool preferRelayFallback = false;
  final List<Map<String, dynamic>> _localIceBuffer = [];
  void Function()? onNeedRelayFallback;
  void Function()? onRemoteHangUp;
  Timer? _keepAliveTimer;
  bool _background = false;
  final List<bool> _prevVideoEnabled = [];
  bool _isCaller = false;
  bool _remoteDescriptionSet = false;
  bool _pcClosed = false;
  final List<StreamSubscription> _subscriptions = [];
  // StreamStateCallback? onAddRemoteStream;clc

  Future<String> createRoom(String fixedRoomId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(fixedRoomId);

    print('Create PeerConnection with config : $configuration');
    _cancelSubscriptions();

    if (preferRelayFallback) {
      configuration['iceTransportPolicy'] = 'relay';
    } else {
      configuration['iceTransportPolicy'] = 'all';
    }
    _pcClosed = false;
    _remoteDescriptionSet = false;

    peerConnection = await createPeerConnection(configuration);
    registerListener();

    if (LocalStream == null) {
      try {
        final stream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': true,
        });
        LocalStream = stream;
      } catch (_) {}
    }
    LocalStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, LocalStream!);
    });
    _isCaller = true;

    peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        RemoteStream = event.streams[0];
        if (_remoteRenderer != null) {
          _remoteRenderer!.srcObject = RemoteStream;
        }
      } else {
        if (RemoteStream != null) {
          RemoteStream!.addTrack(event.track);
          if (_remoteRenderer != null) {
            _remoteRenderer!.srcObject = RemoteStream;
          }
        }
      }
    };

    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      print('Got candidate: ${candidate.toMap()}');
      _localIceCount++;
      if (enableIceBatching) {
        _localIceBuffer.add(candidate.toMap());
      } else {
        await callerCandidatesCollection.add(candidate.toMap());
      }
    };

    peerConnection?.onDataChannel = (RTCDataChannel channel) {
      dataChannel = channel;
    };
    dataChannel = await peerConnection!.createDataChannel(
      'signal',
      RTCDataChannelInit(),
    );

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    this.roomId = roomId;

    final subRoom = roomRef.snapshots().listen((snapshot) async {
      if (_pcClosed) {
        return;
      }
      if (!snapshot.exists) {
        final lr = _localRenderer;
        if (lr != null) {
          await hangUp(lr);
        }
        if (onRemoteHangUp != null) {
          onRemoteHangUp!();
        }
        return;
      }
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      final rd = await peerConnection?.getRemoteDescription();
      if (rd == null && data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        if (_pcClosed) {
          return;
        }
        await peerConnection?.setRemoteDescription(answer);
        _remoteDescriptionSet = true;
        for (final c in _pendingRemoteCandidates) {
          await peerConnection?.addCandidate(c);
        }
        _pendingRemoteCandidates.clear();
      }
    });
    _subscriptions.add(subRoom);

    final subCallee = roomRef.collection('calleeCandidates').snapshots().listen(
      (snapshot) {
        snapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data =
                change.doc.data() as Map<String, dynamic>;
            print('Got new remote ICE candidate: ${jsonEncode(data)}');
            _logRemoteCandidateType('caller', data);
            _remoteIceCount++;

            final cand = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            if (!_remoteDescriptionSet) {
              _pendingRemoteCandidates.add(cand);
            } else {
              try {
                if (_pcClosed) {
                  return;
                }
                peerConnection!.addCandidate(cand);
              } catch (e) {
                print('ICE candidate add error: $e');
              }
            }
          }
        });
      },
    );
    _subscriptions.add(subCallee);

    return roomId;
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (RemoteStream != null)
      RemoteStream!.getTracks().forEach((track) => track.stop());

    if (peerConnection != null) {
      await peerConnection!.close();
      await peerConnection!.dispose();
    }

    _pcClosed = true;
    _remoteDescriptionSet = false;
    _pendingRemoteCandidates.clear();
    _cancelSubscriptions();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }
    _stopKeepAlive();
  }

  Future<void> joinRoom(String roomId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    this.roomId = roomId;
    _cancelSubscriptions();

    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Create PeerConnection with config : $configuration');
      if (preferRelayFallback) {
        configuration['iceTransportPolicy'] = 'relay';
      } else {
        configuration['iceTransportPolicy'] = 'all';
      }
      _pcClosed = false;
      _remoteDescriptionSet = false;
      peerConnection = await createPeerConnection(configuration);

      registerListener();

      if (LocalStream == null) {
        try {
          final stream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': true,
          });
          LocalStream = stream;
        } catch (_) {}
      }
      LocalStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, LocalStream!);
      });
      _isCaller = false;

      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          RemoteStream = event.streams[0];
          if (_remoteRenderer != null) {
            _remoteRenderer!.srcObject = RemoteStream;
          }
        } else {
          if (RemoteStream != null) {
            RemoteStream!.addTrack(event.track);
            if (_remoteRenderer != null) {
              _remoteRenderer!.srcObject = RemoteStream;
            }
          }
        }
      };

      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
        print('Got candidate: ${candidate.toMap()}');
        _localIceCount++;
        if (enableIceBatching) {
          _localIceBuffer.add(candidate.toMap());
        } else {
          await calleeCandidatesCollection.add(candidate.toMap());
        }
      };

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      _remoteDescriptionSet = true;
      await Future.delayed(const Duration(seconds: 2));
      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      await roomRef.update({'answer': answer.toMap()});

      peerConnection?.onDataChannel = (RTCDataChannel channel) {
        dataChannel = channel;
      };
      final subCaller = roomRef
          .collection('callerCandidates')
          .snapshots()
          .listen((snapshot) {
            snapshot.docChanges.forEach((change) {
              if (change.type == DocumentChangeType.added) {
                Map<String, dynamic> cand =
                    change.doc.data() as Map<String, dynamic>;
                _logRemoteCandidateType('callee', cand);
                _remoteIceCount++;
                final c = RTCIceCandidate(
                  cand['candidate'],
                  cand['sdpMid'],
                  cand['sdpMLineIndex'],
                );
                if (!_remoteDescriptionSet) {
                  _pendingRemoteCandidates.add(c);
                } else {
                  try {
                    if (_pcClosed) {
                      return;
                    }
                    peerConnection!.addCandidate(c);
                  } catch (e) {
                    print('ICE candidate add error: $e');
                  }
                }
              }
            });
          });
      _subscriptions.add(subCaller);
    }
    final subRoom = roomRef.snapshots().listen((snapshot) async {
      if (_pcClosed) {
        return;
      }
      if (!snapshot.exists) {
        final lr = _localRenderer;
        if (lr != null) {
          await hangUp(lr);
        }
        if (onRemoteHangUp != null) {
          onRemoteHangUp!();
        }
      }
    });
    _subscriptions.add(subRoom);
  }

  Future<void> openMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo, {
    bool video = true,
    bool audio = true,
  }) async {
    MediaStream? stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({
        'audio':
            audio
                ? {
                  'echoCancellation': true,
                  'noiseSuppression': true,
                  'autoGainControl': true,
                }
                : false,
        'video': video,
      });
    } catch (e) {
      print('getUserMedia error: $e');
      rethrow;
    }

    LocalStream = stream;
    _localRenderer = localVideo;
    _remoteRenderer = remoteVideo;
    localVideo.srcObject = stream;
    try {
      RemoteStream = await createLocalMediaStream('remote');
      remoteVideo.srcObject = RemoteStream;
    } catch (e) {
      print('createLocalMediaStream error: $e');
    }
    try {
      await Helper.setSpeakerphoneOn(true);
    } catch (e) {
      print('setSpeakerphoneOn error: $e');
    }
    final aud = stream.getAudioTracks();
    print('Local audio tracks after getUserMedia: ${aud.length}');
    for (final t in aud) {
      print('Local audio enabled: ${t.enabled}, readyState: ${t}');
    }
  }

  void registerListener() {
    peerConnection?.onAddStream = (MediaStream stream) {
      print('Add Remote Stream');
      RemoteStream = stream;
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
      }
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
      if (enableIceBatching &&
          state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        final rid = roomId;
        if (rid != null && _localIceBuffer.isNotEmpty) {
          final db = FirebaseFirestore.instance;
          final roomRef = db.collection('rooms').doc(rid);
          final isCaller = _isCaller;
          final col =
              isCaller
                  ? roomRef.collection('callerCandidates')
                  : roomRef.collection('calleeCandidates');
          for (final c in _localIceBuffer) {
            col.add(c);
          }
          _localIceBuffer.clear();
          print('Published batched local ICE candidates');
        }
      }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('PeerConnection state changed: $state');
      if (onPeerConnectionState != null) {
        onPeerConnectionState!(state);
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _pcClosed = true;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _printDescriptions('PeerConnection failed');
        if (!preferRelayFallback && onNeedRelayFallback != null) {
          onNeedRelayFallback!();
        }
      }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state changed: $state');
    };

    peerConnection?.onIceConnectionState = (
      RTCIceConnectionState iceConnectionState,
    ) {
      print('ICE connection state changed: $iceConnectionState');
      if (onIceConnectionState != null) {
        onIceConnectionState!(iceConnectionState);
      }
      if (iceConnectionState ==
          RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _printDescriptions('ICE failed');
        if (!preferRelayFallback && onNeedRelayFallback != null) {
          onNeedRelayFallback!();
        }
      }
    };
  }

  void enterBackground() {
    _background = true;
    _prevVideoEnabled.clear();
    final stream = LocalStream;
    if (stream != null) {
      final vids = stream.getVideoTracks();
      for (final t in vids) {
        _prevVideoEnabled.add(t.enabled);
        t.enabled = false;
      }
    }
    _startKeepAlive();
  }

  void exitBackground() {
    _background = false;
    final stream = LocalStream;
    if (stream != null) {
      final vids = stream.getVideoTracks();
      for (int i = 0; i < vids.length; i++) {
        final prev = i < _prevVideoEnabled.length ? _prevVideoEnabled[i] : true;
        vids[i].enabled = prev;
      }
    }
    _prevVideoEnabled.clear();
    _stopKeepAlive();
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final dc = dataChannel;
      if (dc != null) {
        try {
          dc.send(RTCDataChannelMessage('ping'));
        } catch (_) {}
      } else {
        try {
          await peerConnection?.getStats();
        } catch (_) {}
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<void> _printDescriptions(String prefix) async {
    final ld = await peerConnection?.getLocalDescription();
    final rd = await peerConnection?.getRemoteDescription();
    final ls = ld?.sdp ?? '';
    final rs = rd?.sdp ?? '';
    print(
      '$prefix with local=${ld?.type}/${ls.length} remote=${rd?.type}/${rs.length} localICE=$_localIceCount remoteICE=$_remoteIceCount',
    );
  }

  void _logRemoteCandidateType(String side, Map<String, dynamic> data) {
    final raw = (data['candidate'] ?? '') as String;
    String typ = '';
    String proto = '';
    final tMatch = RegExp(r'\btyp\s+(\w+)').firstMatch(raw);
    if (tMatch != null) {
      typ = tMatch.group(1) ?? '';
    }
    final pMatch = RegExp(r'\b(udp|tcp)\b').firstMatch(raw);
    if (pMatch != null) {
      proto = pMatch.group(1) ?? '';
    }
    print('Remote $side candidate typ=$typ proto=$proto');
  }

  void _cancelSubscriptions() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}
