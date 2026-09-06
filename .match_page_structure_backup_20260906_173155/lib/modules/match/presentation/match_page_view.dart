import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/availability/widgets/match_availability_card.dart';

import 'package:versin/modules/match/discovery/widgets/discovery_section_widget.dart';
import 'package:versin/modules/match/discovery/widgets/match_discovery_header.dart';
import 'package:versin/modules/match/discovery/widgets/match_discovery_mode_selector.dart';

import 'package:versin/modules/match/models/match_discovery_mode.dart';

import 'package:versin/modules/match/presentation/match_page_coordinator.dart';

import 'package:versin/modules/match/profile/widgets/connection_profile_card_widget.dart';

import 'package:versin/modules/match/search/widgets/match_search_panel_widget.dart';
import 'package:versin/modules/match/search/widgets/match_search_results_widget.dart';

import 'package:versin/modules/match/team_expansion/widgets/team_expansion_notice.dart';

import 'package:versin/modules/onboarding/widgets/match_username_onboarding_card.dart';

// ============================================================
// MATCH PAGE VIEW
// ============================================================
//
// Responsabilidade exclusiva:
//
// - compor widgets;
// - ler estado do coordinator;
// - encaminhar eventos de UI.
//
// Não cria services/controllers e não executa regra de negócio.
//
// ============================================================

class MatchPageView extends StatelessWidget {
  final MatchPageCoordinator coordinator;

  const MatchPageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final searchState = coordinator.matchSearchController.state;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),

            if (coordinator.isTeamExpansionMode) ...[
              TeamExpansionNotice(
                projectTitle:
                    coordinator.teamExpansionController.displayProjectTitle,
                accentColor: coordinator.matchController.accentNeon,
              ),
              const SizedBox(height: 12),
            ],

            if (coordinator.isSearchPanelOpen)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: MatchSearchPanelWidget(
                  textController: coordinator.searchTextController,
                  focusNode: coordinator.searchFocusNode,
                  isActive: searchState.isActive,
                  accentColor: coordinator.matchController.accentNeon,
                  onChanged: coordinator.handleSearchChanged,
                  onClear: coordinator.clearSearch,
                ),
              ),

            if (coordinator.isSearchPanelOpen && searchState.isActive) ...[
              const SizedBox(height: 16),
              MatchSearchResultsWidget(
                controller: coordinator.matchController,
                isSearching: searchState.isSearching,
                query: searchState.query,
                errorMessage: searchState.errorMessage,
                results: searchState.results,
              ),
            ],

            const SizedBox(height: 12),

            MatchDiscoveryHeader(
              isTeamExpansionMode: coordinator.isTeamExpansionMode,
              isSearchPanelOpen: coordinator.isSearchPanelOpen,
              hasPublicProfile: coordinator.hasPublicProfile,
              hasActiveFilters: coordinator.filterState.hasActiveFilters,
              activeFilterCount: coordinator.filterState.activeFilterCount,
              accentColor: coordinator.matchController.accentNeon,
              onSearch: coordinator.toggleSearchPanel,
              onPublicProfile: () {
                unawaited(coordinator.openPublicProfile(context));
              },
              onProjects: () {
                unawaited(coordinator.openProjects(context));
              },
              onFilters: () {
                unawaited(coordinator.openFilters(context));
              },
              onInfo: () {
                coordinator.openDiscoveryInfo(context);
              },
            ),

            const SizedBox(height: 10),

            if (!coordinator.isInitializingMatch &&
                coordinator.matchController.requiresUsername) ...[
              MatchUsernameOnboardingCard(
                controller: coordinator.onboardingController,
                accentColor: coordinator.matchController.accentNeon,
                onUsernameSaved: coordinator.refreshUi,
              ),
              const SizedBox(height: 10),
            ],

            ConnectionProfileCardWidget(
              matchController: coordinator.matchController,
              profileController: coordinator.professionalProfileController,
              isInitializingMatch: coordinator.isInitializingMatch,
              onEditProfile: () {
                unawaited(coordinator.openProfessionalProfileSettings(context));
              },
            ),

            const SizedBox(height: 10),

            _LockedInteraction(
              unlocked: coordinator.isInteractionUnlocked,
              onLockedTap: coordinator.ensureInteractionUnlocked,
              child: MatchDiscoveryModeSelector(
                activeMode: coordinator.discoveryController.activeMode,
                disabled:
                    coordinator.isInitializingMatch ||
                    coordinator.isDiscoveryBusy,
                accentColor: coordinator.matchController.accentNeon,
                onModeSelected: (mode) {
                  return coordinator.handleDiscoveryModeSelected(context, mode);
                },
              ),
            ),

            if (coordinator.isAvailabilityVisible) ...[
              const SizedBox(height: 10),
              MatchAvailabilityCard(
                controller: coordinator.availabilityController,
                accentColor: coordinator.matchController.accentNeon,
                onActivate: () {
                  unawaited(
                    coordinator.handleDiscoveryModeSelected(
                      context,
                      MatchDiscoveryMode.global,
                    ),
                  );
                },
                onClear: () {
                  unawaited(coordinator.clearAvailability(context));
                },
              ),
            ],

            const SizedBox(height: 14),

            _LockedInteraction(
              unlocked: coordinator.isInteractionUnlocked,
              onLockedTap: coordinator.ensureInteractionUnlocked,
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: DiscoverySectionWidget(
                      key: ValueKey<String>(
                        coordinator.matchController.discoveryUser?.id ??
                            'discovery-empty',
                      ),
                      controller: coordinator.matchController,
                      isInitializingMatch:
                          coordinator.isInitializingMatch ||
                          coordinator.teamExpansionController.isBusy,
                      isTeamExpansionMode: coordinator.isTeamExpansionMode,
                      onInviteUser: coordinator.isTeamExpansionMode
                          ? (userId) {
                              return coordinator.inviteUserToProject(
                                context,
                                userId,
                              );
                            }
                          : null,
                      onListenDemo: (userId) {
                        return coordinator.openUserDemo(context, userId);
                      },
                    ),
                  ),

                  if (coordinator.demoController.isLoading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: coordinator.matchController.accentNeon,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOCKED INTERACTION
// ============================================================
//
// Remove duplicação de:
//
// GestureDetector
//   → IgnorePointer
//      → Opacity
//
// ============================================================

class _LockedInteraction extends StatelessWidget {
  final bool unlocked;
  final VoidCallback onLockedTap;
  final Widget child;

  const _LockedInteraction({
    required this.unlocked,
    required this.onLockedTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: unlocked ? null : onLockedTap,
      child: IgnorePointer(
        ignoring: !unlocked,
        child: Opacity(opacity: unlocked ? 1 : 0.42, child: child),
      ),
    );
  }
}
