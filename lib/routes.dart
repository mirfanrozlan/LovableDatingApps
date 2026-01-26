import 'package:flutter/material.dart';
import 'views/splash_screen.dart';
import 'views/auth/login_view.dart';
import 'views/auth/forgot_password_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/check_email_view.dart';
import 'views/home/home_view.dart';
import 'views/messages/messages_list_view.dart';
import 'views/messages/chat_view.dart';
import 'views/messages/calling_view.dart';
import 'views/messages/video_call_view.dart';
import 'views/messages/incoming_call_view.dart';
import 'views/discover/discover_card_view.dart';
import 'views/discover/discover_detail_view.dart';
import 'views/discover/nearby_users_view.dart';
import 'views/friends/friends_home_view.dart';
import 'views/moments/moments_view.dart';
import 'views/me/me_view.dart';
import 'views/me/account_view.dart';
import 'views/me/privacy_view.dart';
import 'views/me/notifications_view.dart';
import 'views/me/edit_profile_view.dart';
import 'views/me/preferences_view.dart';
import 'views/profile/user_profile_view.dart';

class AppRoutes {
  static const login = '/login';
  static const forgot = '/forgot';
  static const register = '/register';
  static const checkEmail = '/check-email';
  static const messages = '/messages';
  static const chat = '/chat';
  static const call = '/call';
  static const videoCall = '/video-call';
  static const incomingCall = '/incoming-call';
  static const discover = '/discover';
  static const discoverDetail = '/discover-detail';
  static const nearby = '/nearby';
  static const friends = '/friends';
  static const moments = '/moments';
  static const me = '/me';
  static const account = '/account';
  static const privacy = '/privacy';
  static const notifications = '/notifications';
  static const editProfile = '/edit-profile';
  static const preferences = '/preferences';
  static const home = '/home';
  static const userProfile = '/user-profile';
  static const splash = '/splash';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginView(),
    forgot: (_) => const ForgotPasswordView(),
    register: (_) => const RegisterView(),
    checkEmail: (_) => const CheckEmailView(),
    messages: (_) => MessagesListView(),
    chat: (_) => const ChatView(),
    call: (_) => const CallingView(),
    videoCall: (_) => const VideoCallView(),
    incomingCall: (_) => const IncomingCallView(),
    discover: (_) => DiscoverCardView(),
    discoverDetail: (_) => const DiscoverDetailView(),
    nearby: (_) => const NearbyUsersView(),
    friends: (_) => const FriendsHomeView(),
    moments: (_) => MomentsView(),
    me: (_) => const MeView(),
    account: (_) => const AccountView(),
    privacy: (_) => const PrivacyView(),
    notifications: (_) => const NotificationsView(),
    editProfile: (_) => const EditProfileView(),
    preferences: (_) => const PreferencesView(),
    home: (_) => const HomeView(),
    userProfile: (_) => const UserProfileView(),
  };
}
