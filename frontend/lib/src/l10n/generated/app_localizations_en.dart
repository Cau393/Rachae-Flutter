// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rachae';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get retryLabel => 'Retry';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveLabel => 'Save';

  @override
  String get editLabel => 'Edit';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get confirmLabel => 'Confirm';

  @override
  String get closeLabel => 'Close';

  @override
  String get backLabel => 'Back';

  @override
  String get doneLabel => 'Done';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get searchLabel => 'Search';

  @override
  String get noResultsLabel => 'No results found.';

  @override
  String get requiredFieldError => 'This field is required.';

  @override
  String get invalidAmountError => 'Invalid amount.';

  @override
  String get unknownError => 'Unknown error. Please try again.';

  @override
  String get networkError => 'No connection. Check your internet.';

  @override
  String get navDashboard => 'Home';

  @override
  String get navGroups => 'Groups';

  @override
  String get navFriends => 'Friends';

  @override
  String get navProfile => 'Profile';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get loginTitle => 'Split expenses without friction';

  @override
  String get loginSubtitle => 'Sign in with Google to continue.';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Continue with Apple';

  @override
  String get unsupportedPlatformMessage =>
      'Google sign-in is only available on web and iOS.';

  @override
  String get oauthFailed => 'Could not start sign-in. Please try again.';

  @override
  String get loginLoading => 'Signing in...';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get dashboardStubMessage => 'Dashboard coming in Phase 18';

  @override
  String get dashboardYouOwe => 'You owe';

  @override
  String get dashboardYouAreOwed => 'You are owed';

  @override
  String get dashboardNetBalance => 'Net balance';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardNoActivity => 'No activity yet.';

  @override
  String get dashboardActivityEndOfList => 'You\'re all caught up.';

  @override
  String get dashboardAddExpense => 'Add expense';

  @override
  String get dashboardShortcutPendingApprovals => 'Pending payments to approve';

  @override
  String get dashboardShortcutOwedToYou => 'Who owes you';

  @override
  String get dashboardShortcutPendingSettlements => 'Pending settlements';

  @override
  String get dashboardPendingApprovalsTitle => 'Pending approvals';

  @override
  String get dashboardPendingApprovalsEmpty =>
      'No payments waiting for your confirmation.';

  @override
  String get dashboardOwedToYouTitle => 'Who owes you';

  @override
  String get dashboardOwedToYouEmpty => 'No one owes you right now.';

  @override
  String get dashboardPendingSettlementsTitle => 'Pending settlements';

  @override
  String get dashboardPendingOutgoingSection =>
      'Payments you recorded (awaiting their confirmation)';

  @override
  String get dashboardYouOweSection => 'Balances you owe';

  @override
  String get dashboardYouOweEmpty => 'You do not owe anyone right now.';

  @override
  String get dashboardYouOweSubtitle => 'Tap to settle up';

  @override
  String get dashboardPulledToRefresh => 'Refreshed';

  @override
  String get activityExpenseAdded => 'Expense added';

  @override
  String get activitySettlementRecorded => 'Payment recorded';

  @override
  String get activitySettlementConfirmed => 'Payment confirmed';

  @override
  String activityPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get activitySourcePersonal => 'Personal';

  @override
  String get activityYouPaid => 'You paid';

  @override
  String get activityAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsEmpty => 'No groups yet. Create one!';

  @override
  String get groupsCreateFab => 'New group';

  @override
  String groupMemberCount(int count) {
    return '$count members';
  }

  @override
  String get groupYourBalance => 'Your balance';

  @override
  String groupBalancePositive(String amount) {
    return 'Owed R\$ $amount';
  }

  @override
  String groupBalanceNegative(String amount) {
    return 'You owe R\$ $amount';
  }

  @override
  String get groupBalanceZero => 'Settled';

  @override
  String get createGroupTitle => 'New group';

  @override
  String get createGroupNameLabel => 'Group name';

  @override
  String get createGroupNameHint => 'E.g. Road trip';

  @override
  String get createGroupTypeLabel => 'Type';

  @override
  String get createGroupTypeHome => 'Home';

  @override
  String get createGroupTypeTrip => 'Trip';

  @override
  String get createGroupTypeCouple => 'Couple';

  @override
  String get createGroupTypeOther => 'Other';

  @override
  String get createGroupCurrencyLabel => 'Group currency';

  @override
  String get createGroupAddMembers => 'Add members';

  @override
  String get createGroupMemberSearchHint => 'Search by email or phone';

  @override
  String get createGroupSimplifyDebts => 'Simplify debts automatically';

  @override
  String get createGroupButton => 'Create group';

  @override
  String get createGroupSuccess => 'Group created!';

  @override
  String get createGroupError => 'Error creating group. Try again.';

  @override
  String get groupDetailTabExpenses => 'Expenses';

  @override
  String get groupDetailTabBalances => 'Balances';

  @override
  String get groupDetailTabMembers => 'Members';

  @override
  String get groupDetailTabActivity => 'Activity';

  @override
  String get groupDetailNoExpenses => 'No expenses yet.';

  @override
  String get groupDetailAddExpense => 'Add expense';

  @override
  String get groupDetailSettleUp => 'Settle up';

  @override
  String get groupDetailSettings => 'Group settings';

  @override
  String get groupDetailSimplifiedDebts => 'Simplified debts';

  @override
  String get groupDetailNoDebts => 'Everyone is settled!';

  @override
  String groupDetailOwes(String payer, String amount, String receiver) {
    return '$payer owes $amount to $receiver';
  }

  @override
  String get groupDetailRoleAdmin => 'Admin';

  @override
  String get groupDetailRoleMember => 'Member';

  @override
  String get groupDetailRoleViewer => 'Viewer';

  @override
  String get groupMemberCurrentUserSuffix => '(You)';

  @override
  String get groupAddFriendsButton => 'Add friends';

  @override
  String get groupAddMembersTitle => 'Add friends to group';

  @override
  String get groupAddMembersNoFriends => 'You have no friends to add yet.';

  @override
  String get groupAddMembersAllInGroup =>
      'All your friends are already in this group.';

  @override
  String get groupAddMembersAddButton => 'Add';

  @override
  String get groupAddMembersConfirmButton => 'Add to group';

  @override
  String groupAddMembersConfirmWithCount(int count) {
    return 'Add ($count)';
  }

  @override
  String groupAddMembersAddedSuccess(int count) {
    return 'Added $count friends to the group.';
  }

  @override
  String groupAddMembersPartialFailure(int failed, int total) {
    return '$failed of $total could not be added.';
  }

  @override
  String get groupAddMembersSelectAtLeastOne => 'Select at least one friend.';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get groupSettingsDeleteGroup => 'Delete group';

  @override
  String get groupSettingsDeleteConfirm =>
      'Are you sure you want to delete this group? This cannot be undone.';

  @override
  String get groupSettingsLeaveGroup => 'Leave group';

  @override
  String get groupSettingsLeaveConfirm =>
      'Are you sure you want to leave this group?';

  @override
  String get groupSettingsRemoveMember => 'Remove member';

  @override
  String groupSettingsRemoveMemberConfirm(String name) {
    return 'Remove $name from the group?';
  }

  @override
  String get groupSettingsChangeRole => 'Change role';

  @override
  String get groupSettingsSaveSuccess => 'Settings saved.';

  @override
  String get groupSettingsDangerZone => 'Danger zone';

  @override
  String get addExpenseTitle => 'New expense';

  @override
  String get addExpenseAmountLabel => 'Amount';

  @override
  String get addExpenseAmountHint => '0.00';

  @override
  String get addExpenseDescriptionLabel => 'Description';

  @override
  String get addExpenseDescriptionHint => 'E.g. Dinner at the restaurant';

  @override
  String get addExpensePaidByLabel => 'Paid by';

  @override
  String get addExpenseDateLabel => 'Date';

  @override
  String get addExpenseCategoryLabel => 'Category';

  @override
  String get addExpenseSplitMethodLabel => 'Split method';

  @override
  String get addExpenseSplitMethodEqual => 'Equally';

  @override
  String get addExpenseSplitMethodExact => 'Exact amounts';

  @override
  String get addExpenseSplitMethodPercentage => 'Percentage';

  @override
  String get addExpenseSplitMethodShares => 'Shares';

  @override
  String get addExpenseReceiptLabel => 'Add receipt';

  @override
  String get addExpenseSaveButton => 'Save expense';

  @override
  String get addExpenseSuccess => 'Expense added!';

  @override
  String get addExpenseError => 'Error saving. Try again.';

  @override
  String get addExpenseTimeoutError =>
      'The request timed out. Check your connection and try again.';

  @override
  String get addExpenseReceiptUploadPartialFailure =>
      'Expense saved, but some receipts failed to upload.';

  @override
  String get addExpenseFriendLabel => 'Friend';

  @override
  String get addExpenseFriendHint =>
      'Choose the friend involved in this expense';

  @override
  String get addExpenseFriendRequired => 'Choose a friend for this expense.';

  @override
  String get addExpenseNoFriendsAvailable =>
      'Add a friend first to create a personal shared expense.';

  @override
  String get addExpenseAmountInvalid => 'Enter an amount greater than zero.';

  @override
  String get addExpenseSplitDoesNotMatch =>
      'Split does not match the total amount.';

  @override
  String get addExpenseSplitAutoChip => 'Auto';

  @override
  String addExpenseSplitTotalExact(String sum, String total) {
    return 'Total: $sum / $total';
  }

  @override
  String addExpenseSplitTotalPercentage(String percentage) {
    return '$percentage%';
  }

  @override
  String get addExpenseCurrencyLabel => 'Currency';

  @override
  String addExpenseConvertedPreview(String amount, String currency) {
    return '≈ $amount $currency in group currency';
  }

  @override
  String get categoryGeral => 'General';

  @override
  String get categoryComida => 'Food';

  @override
  String get categoryTransporte => 'Transport';

  @override
  String get categoryMoradia => 'Housing';

  @override
  String get categoryLazer => 'Entertainment';

  @override
  String get categoryViagem => 'Travel';

  @override
  String get categoryUtilidades => 'Utilities';

  @override
  String get expenseDetailTitle => 'Expense details';

  @override
  String expenseDetailPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String get expenseDetailSplitBreakdown => 'Split';

  @override
  String get expenseDetailReceipts => 'Receipts';

  @override
  String get expenseDetailNoReceipts => 'No receipts attached.';

  @override
  String get expenseDetailEditButton => 'Edit';

  @override
  String get expenseDetailEditComingSoon => 'Editing is not available yet.';

  @override
  String get expenseDetailDeleteButton => 'Delete';

  @override
  String get expenseDetailDeleteConfirm =>
      'Delete this expense? This cannot be undone.';

  @override
  String get expenseDetailDeleteSuccess => 'Expense deleted.';

  @override
  String expenseDetailOwes(String name, String amount) {
    return '$name owes $amount';
  }

  @override
  String get expenseDetailSettled => 'Settled';

  @override
  String expenseDetailLastModified(String date) {
    return 'Last modified: $date';
  }

  @override
  String get settleUpTitle => 'Settle up';

  @override
  String get settleUpPayerLabel => 'From:';

  @override
  String get settleUpReceiverLabel => 'Pay to';

  @override
  String get settleUpAmountLabel => 'Amount';

  @override
  String get settleUpNoteLabel => 'Note (optional)';

  @override
  String get settleUpNoteHint => 'E.g. Rent split';

  @override
  String get settleUpRecordButton => 'Record payment';

  @override
  String get settleUpSuccess => 'Payment recorded! Awaiting confirmation.';

  @override
  String get settleUpError => 'Error recording payment.';

  @override
  String get settleUpConfirmButton => 'Confirm receipt';

  @override
  String get settleUpDisputeButton => 'Dispute';

  @override
  String get settleUpDisputeConfirm => 'Dispute this payment?';

  @override
  String get settleUpAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String get settleUpConfirmed => 'Confirmed';

  @override
  String get settleUpDisputed => 'Disputed';

  @override
  String settleUpSuggestedAmount(String amount) {
    return 'Suggested: $amount';
  }

  @override
  String get settleUpPaymentProofSection => 'Payment proof (optional)';

  @override
  String get settleUpAddProofLabel => 'Add proof';

  @override
  String get settleUpProofUploadError => 'Could not upload payment proof.';

  @override
  String get settleUpOffsetButton => 'Offset with existing credit';

  @override
  String get settleUpOffsetConfirmTitle => 'Offset this debt?';

  @override
  String get settleUpOffsetConfirmMessage =>
      'This will use your existing credit with this person to clear this group debt without moving cash.';

  @override
  String get settleUpOffsetConfirmAction => 'Offset balance';

  @override
  String get pendingSettlementYouPaidBeforeAmount => 'You paid ';

  @override
  String pendingSettlementYouPaidAfterAmount(String receiverName) {
    return ' to $receiverName';
  }

  @override
  String pendingSettlementReceivedBeforeAmount(String payerName) {
    return '$payerName sent you ';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsEmpty => 'No friends yet. Invite someone!';

  @override
  String get friendsInviteButton => 'Invite friend';

  @override
  String friendsOwes(String amount) {
    return 'Owes $amount';
  }

  @override
  String friendsOwed(String amount) {
    return 'Owes you $amount';
  }

  @override
  String get friendsEven => 'Even';

  @override
  String get friendsSearchHint => 'Search friends';

  @override
  String get friendInviteTitle => 'Invite friend';

  @override
  String get friendInviteBody =>
      'We create a unique link. Share it in any app—the other person opens it, signs in, and accepts.';

  @override
  String get friendInviteButton => 'Generate invite link';

  @override
  String get friendInviteSuccess => 'Invite sent!';

  @override
  String get friendInviteLinkCopied => 'Invite link copied!';

  @override
  String get friendAcceptInviteButton => 'Accept invite';

  @override
  String get friendAcceptSuccess => 'Invite accepted! You are now friends.';

  @override
  String get inviteGetTheAppHint => 'Prefer the app? Get it here.';

  @override
  String get inviteAppStoreButton => 'App Store';

  @override
  String get invitePlayStoreButton => 'Google Play';

  @override
  String get inviteOpenInAppHint =>
      'Already have Rachae installed? Open the app to accept this invite.';

  @override
  String get inviteOpenInAppButton => 'Open in app';

  @override
  String get friendDetailTitle => 'Details';

  @override
  String get friendDetailNetBalance => 'Balance between you';

  @override
  String get friendDetailPendingSettlements => 'Pending settlements';

  @override
  String get friendDetailSharedExpenses => 'Shared expenses';

  @override
  String get friendDetailSharedGroups => 'Groups in common';

  @override
  String get friendDetailNoSharedExpenses => 'No shared expenses.';

  @override
  String get friendDetailSettleUpButton => 'Settle up';

  @override
  String get friendDetailAddToGroupButton => 'Add to group';

  @override
  String get friendDetailNoEligibleGroups =>
      'No groups available for this friend.';

  @override
  String friendDetailAddedToGroupSuccess(String friendName, String groupName) {
    return '$friendName was added to $groupName!';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailReadOnly => 'Managed by Google';

  @override
  String get profileDefaultCurrencyLabel => 'Default currency';

  @override
  String get profileSaveButton => 'Save changes';

  @override
  String get profileSaveSuccess => 'Profile updated!';

  @override
  String get profileAvatarChangeButton => 'Change photo';

  @override
  String get profileAvatarUploadError =>
      'Could not update your photo. Please try again.';

  @override
  String get profileSignOutButton => 'Sign out';

  @override
  String get profileSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileDeleteAccountButton => 'Delete my account';

  @override
  String get profileDeleteAccountConfirmTitle => 'Delete account';

  @override
  String get profileDeleteAccountConfirm =>
      'Deleting your account is permanent and cannot be undone. Continue?';

  @override
  String get profileDeleteAccountSuccess => 'Account deleted.';

  @override
  String get profileNotificationsSection => 'Notifications';

  @override
  String get profilePushExpenseCreated => 'New expense added';

  @override
  String get profilePushSettlementRecorded => 'Payment recorded';

  @override
  String get profilePushGroupInvitation => 'Group invitation';

  @override
  String get profileEmailExpenseCreated => 'Email: new expense';

  @override
  String get profileEmailSettlementRecorded => 'Email: payment recorded';

  @override
  String get profileAdFreeSection => 'Ad-free plan';

  @override
  String get profileAdFreeActive => 'Plan active — thank you for your support!';

  @override
  String profileAdFreeExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String get profileAdFreeMonthlyLabel => 'Monthly';

  @override
  String get profileAdFreeYearlyLabel => 'Yearly';

  @override
  String get profileAdFreeLifetimeLabel => 'Lifetime';

  @override
  String get profileAdFreePlanUnknown => 'Active subscription';

  @override
  String profileAdFreeCurrentPlanLabel(String planName) {
    return 'Current plan: $planName';
  }

  @override
  String get profilePlanChangeStripePortalFootnote =>
      'Use Manage subscription to change your plan. Stripe applies upgrades, downgrades, and billing timing according to your subscription.';

  @override
  String get profileIosSubscriptionChangeFootnote =>
      'To change your billing period or cancel, use Manage subscription. Apple applies upgrades and downgrades in one subscription—avoid buying a second plan from the paywall while already subscribed.';

  @override
  String get profileSeeRachaeProPlansButton => 'See plans';

  @override
  String get profileSubscriptionManagedElsewhere =>
      'Subscription changes are not available in the app. Contact support if you need help.';

  @override
  String profileAdFreePlanExpires(String date) {
    return 'Valid until $date';
  }

  @override
  String get profileUpgradeMonthlyButton => 'Subscribe to monthly plan';

  @override
  String get profileUpgradeYearlyButton => 'Subscribe to yearly plan';

  @override
  String get profileUpgradeButton => 'Remove ads';

  @override
  String get profileManageSubscriptionButton => 'Manage subscription';

  @override
  String get profileExportButton => 'Export data';

  @override
  String get profileTermsOfUseButton => 'Terms of Use (EULA)';

  @override
  String get profilePrivacyPolicyButton => 'Privacy Policy';

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportDateFromLabel => 'From date';

  @override
  String get exportDateToLabel => 'To date';

  @override
  String get exportGroupLabel => 'Group (optional)';

  @override
  String get exportAllGroups => 'All groups';

  @override
  String get exportGroupAll => 'All groups';

  @override
  String get exportShareButton => 'Share PDF';

  @override
  String get exportGenerateButton => 'Generate report';

  @override
  String get exportGenerating => 'Generating report...';

  @override
  String get exportSuccess => 'Report generated successfully!';

  @override
  String get exportError => 'Error generating report. Try again.';

  @override
  String get sectionLoadError => 'Could not load this section. Try again.';

  @override
  String get profileLoadError =>
      'Could not load your profile. Check your connection and try again.';

  @override
  String get profileAdsLoadError => 'Could not load subscription status.';

  @override
  String get profileCheckoutSessionError =>
      'Could not start checkout. Try again.';

  @override
  String get profileCheckoutAlreadySubscribed =>
      'You already have an active subscription.';

  @override
  String get profileCheckoutCannotOpenUrl =>
      'Could not open the payment page. Try again.';

  @override
  String get profileIapOfferingsUnavailable =>
      'Subscription options are not available right now. Try again later.';

  @override
  String get profileIapNotConfigured =>
      'In-app purchases are not configured yet. Create the products in App Store Connect and link them to an offering in the RevenueCat dashboard.';

  @override
  String get profileRevenueCatMissingApiKey =>
      'In-app purchases are not configured in this build. Run the app with REVENUECAT_IOS_API_KEY (e.g. flutter run --dart-define-from-file=../.env from the frontend folder), then set up products in App Store Connect and RevenueCat.';

  @override
  String get exportPdfDocumentTitle => 'Rachae - expense report';

  @override
  String get exportPdfEmptyReport => 'No data for the selected filters.';

  @override
  String exportPdfPeriod(String fromDate, String toDate) {
    return 'Period: $fromDate - $toDate';
  }

  @override
  String get exportPdfTotalSpent => 'Group total spent';

  @override
  String get exportPdfPerPersonTitle => 'Per person (paid / owed / net)';

  @override
  String get exportPdfColumnPerson => 'Person';

  @override
  String get exportPdfColumnPaid => 'Paid';

  @override
  String get exportPdfColumnOwed => 'Owed';

  @override
  String get exportPdfColumnNet => 'Net';

  @override
  String get exportPdfExpensesTitle => 'Expense line items';

  @override
  String get exportPdfNoExpenses => 'No expenses in this period.';

  @override
  String get exportPdfExpenseDescription => 'Description';

  @override
  String get exportPdfExpenseAmount => 'Amount';

  @override
  String get exportPdfExpenseDate => 'Date';

  @override
  String get exportPdfExpenseCategory => 'Category';

  @override
  String get exportPdfSettlementsTitle => 'Settlement history';

  @override
  String get exportPdfNoSettlements => 'No settlements in this period.';

  @override
  String get exportPdfSettlementPayer => 'Payer';

  @override
  String get exportPdfSettlementReceiver => 'Receiver';

  @override
  String get exportPdfSettlementAmount => 'Amount';

  @override
  String get exportPdfSettlementDate => 'Date';

  @override
  String get adBannerFallback => '';

  @override
  String get adFreeUpgradeTitle => 'Remove ads';

  @override
  String get adFreeUpgradeDescription =>
      'Enjoy Rachae without interruptions. A fair price, no tracking.';

  @override
  String get adFreeMonthlyPlan => 'Monthly';

  @override
  String get adFreeYearlyPlan => 'Yearly';

  @override
  String get adFreeMonthlyPlanOption => 'Monthly (R\$ 4.99)';

  @override
  String get adFreeYearlyPlanOption => 'Yearly (R\$ 29.99)';

  @override
  String get adFreeUpgradeButton => 'Subscribe';

  @override
  String get adFreeCancelAnytime => 'Cancel anytime.';

  @override
  String adFreeYearlySavingsBadge(int percent) {
    return 'Save $percent%';
  }

  @override
  String get adFreeYearlyBestValueBadge => 'Best value';

  @override
  String get adFreeSuccessTitle => 'You\'re ad-free!';

  @override
  String get adFreeSuccessMessage =>
      'Enjoy Rachae without interruptions. Thanks for your support!';

  @override
  String get adFreeRestorePurchasesButton => 'Restore purchases';

  @override
  String get adFreeRestorePurchasesSuccess =>
      'Purchases restored — you\'re ad-free!';

  @override
  String get adFreeRestorePurchasesNotFound =>
      'No active subscription found to restore.';

  @override
  String get profileManageSubscriptionAppleUrlError =>
      'Could not open subscription management. Try again.';

  @override
  String get stageOneReady => 'Stage 1 foundation is ready.';

  @override
  String get homeTitle => 'Home';

  @override
  String get signOut => 'Sign out';

  @override
  String authenticatedMessage(String email) {
    return 'Signed in as $email';
  }
}
