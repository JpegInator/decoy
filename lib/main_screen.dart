import 'package:flutter/material.dart';
import 'package:decoy/app_theme.dart';
import 'package:decoy/user_profile.dart';
import 'package:decoy/step_counter_screen.dart';
import 'package:decoy/friends_ranking_screen.dart';
import 'package:isar/isar.dart';
import 'package:decoy/db/user_model.dart' as model;
import 'package:decoy/services/step_counter_service.dart';
import 'package:decoy/deep_seek_chat.dart';
import 'package:decoy/water_screen.dart';
import 'package:decoy/services/health_reminder_service.dart';
import 'package:decoy/services/water_provider.dart';
import 'package:decoy/services/step_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final Isar isar;
  final model.User currentUser;
  final StepCounterService stepCounterService;
  final HealthReminderService healthReminderService;

  const MainScreen({
    required this.isar,
    required this.currentUser,
    required this.stepCounterService,
    required this.healthReminderService,
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    stepProvider.loadDailyGoal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.mainGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Image.asset('assets/images/group_one.png', height: 80),
                        const SizedBox(height: 40),
                        const Text(
                          'Статистика',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStatsSection(context),
                        const SizedBox(height: 24),
                        _buildFriendsRatingButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(context),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer2<StepProvider, WaterProvider>(
      builder: (_, stepProvider, waterProvider, __) {
        return Column(
          children: [
            _buildStatCard(
              title: 'Шаги',
              icon: Icons.directions_walk,
              current: stepProvider.steps,
              goal: stepProvider.dailyGoal,
              color: const Color.fromARGB(255, 9, 58, 20),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              title: 'Вода',
              icon: Icons.local_drink,
              current: waterProvider.waterConsumed,
              goal: waterProvider.dailyGoal,
              color: AppColors.primaryBlue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required int current,
    required int goal,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$current/$goal',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsRatingButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FriendsRankingScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        child: const Text(
          'Рейтинг друзей',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            iconPath: 'assets/images/profile_60.png',
            label: 'Профиль',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  isar: widget.isar, 
                  currentUser: widget.currentUser
                ),
              ),
            ),
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/images/water_60.png',
            label: 'Вода',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WaterScreen()),
            ),
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/images/steps_60.png',
            label: 'Шаги',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StepCounterScreen(
                  stepCounterService: widget.stepCounterService,
                  healthReminderService: widget.healthReminderService,
                  isar: widget.isar,
                ),
              ),
            ),
          ),
          _buildNavItem(
            context,
            iconPath: 'assets/images/chat_60.png',
            label: 'Чат',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Image.asset(
            iconPath,
            width: 36,
            height: 36,
            color: Colors.black,
          ),
          onPressed: onPressed,
          splashRadius: 24,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}