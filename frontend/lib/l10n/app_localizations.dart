import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rachae'**
  String get appTitle;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @noResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResultsLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredFieldError;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get invalidAmountError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error. Please try again.'**
  String get unknownError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet.'**
  String get networkError;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navDashboard;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Split expenses without friction'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to continue.'**
  String get loginSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInWithApple;

  /// No description provided for @unsupportedPlatformMessage.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is only available on web and iOS.'**
  String get unsupportedPlatformMessage;

  /// No description provided for @oauthFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start sign-in. Please try again.'**
  String get oauthFailed;

  /// No description provided for @loginLoading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginLoading;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboardTitle;

  /// No description provided for @dashboardStubMessage.
  ///
  /// In en, this message translates to:
  /// **'Dashboard coming in Phase 18'**
  String get dashboardStubMessage;

  /// No description provided for @dashboardYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get dashboardYouOwe;

  /// No description provided for @dashboardYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get dashboardYouAreOwed;

  /// No description provided for @dashboardNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net balance'**
  String get dashboardNetBalance;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get dashboardAddExpense;

  /// No description provided for @dashboardShortcutPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending payments to approve'**
  String get dashboardShortcutPendingApprovals;

  /// No description provided for @dashboardShortcutOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Expenses others owe you'**
  String get dashboardShortcutOwedToYou;

  /// No description provided for @dashboardShortcutPendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'Pending settlements'**
  String get dashboardShortcutPendingSettlements;

  /// No description provided for @dashboardPendingApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get dashboardPendingApprovalsTitle;

  /// No description provided for @dashboardPendingApprovalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments waiting for your confirmation.'**
  String get dashboardPendingApprovalsEmpty;

  /// No description provided for @dashboardOwedToYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses others owe you'**
  String get dashboardOwedToYouTitle;

  /// No description provided for @dashboardOwedToYouEmpty.
  ///
  /// In en, this message translates to:
  /// **'No expenses where you paid and others owe you yet.'**
  String get dashboardOwedToYouEmpty;

  /// No description provided for @dashboardPendingSettlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending settlements'**
  String get dashboardPendingSettlementsTitle;

  /// No description provided for @dashboardPendingOutgoingSection.
  ///
  /// In en, this message translates to:
  /// **'Payments you recorded (awaiting their confirmation)'**
  String get dashboardPendingOutgoingSection;

  /// No description provided for @dashboardYouOweSection.
  ///
  /// In en, this message translates to:
  /// **'Balances you owe'**
  String get dashboardYouOweSection;

  /// No description provided for @dashboardYouOweEmpty.
  ///
  /// In en, this message translates to:
  /// **'You do not owe anyone right now.'**
  String get dashboardYouOweEmpty;

  /// No description provided for @dashboardYouOweSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to settle up'**
  String get dashboardYouOweSubtitle;

  /// No description provided for @dashboardPulledToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get dashboardPulledToRefresh;

  /// No description provided for @activityExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get activityExpenseAdded;

  /// No description provided for @activitySettlementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get activitySettlementRecorded;

  /// No description provided for @activitySettlementConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get activitySettlementConfirmed;

  /// No description provided for @activityPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String activityPaidBy(String name);

  /// No description provided for @activitySourcePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get activitySourcePersonal;

  /// No description provided for @activityYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get activityYouPaid;

  /// No description provided for @activityAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get activityAwaitingConfirmation;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @groupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one!'**
  String get groupsEmpty;

  /// No description provided for @groupsCreateFab.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupsCreateFab;

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMemberCount(int count);

  /// No description provided for @groupYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get groupYourBalance;

  /// No description provided for @groupBalancePositive.
  ///
  /// In en, this message translates to:
  /// **'Owed R\$ {amount}'**
  String groupBalancePositive(String amount);

  /// No description provided for @groupBalanceNegative.
  ///
  /// In en, this message translates to:
  /// **'You owe R\$ {amount}'**
  String groupBalanceNegative(String amount);

  /// No description provided for @groupBalanceZero.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get groupBalanceZero;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get createGroupTitle;

  /// No description provided for @createGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get createGroupNameLabel;

  /// No description provided for @createGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Road trip'**
  String get createGroupNameHint;

  /// No description provided for @createGroupTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get createGroupTypeLabel;

  /// No description provided for @createGroupTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get createGroupTypeHome;

  /// No description provided for @createGroupTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get createGroupTypeTrip;

  /// No description provided for @createGroupTypeCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get createGroupTypeCouple;

  /// No description provided for @createGroupTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get createGroupTypeOther;

  /// No description provided for @createGroupCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Group currency'**
  String get createGroupCurrencyLabel;

  /// No description provided for @createGroupAddMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get createGroupAddMembers;

  /// No description provided for @createGroupMemberSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or phone'**
  String get createGroupMemberSearchHint;

  /// No description provided for @createGroupSimplifyDebts.
  ///
  /// In en, this message translates to:
  /// **'Simplify debts automatically'**
  String get createGroupSimplifyDebts;

  /// No description provided for @createGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupButton;

  /// No description provided for @createGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group created!'**
  String get createGroupSuccess;

  /// No description provided for @createGroupError.
  ///
  /// In en, this message translates to:
  /// **'Error creating group. Try again.'**
  String get createGroupError;

  /// No description provided for @groupDetailTabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get groupDetailTabExpenses;

  /// No description provided for @groupDetailTabBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get groupDetailTabBalances;

  /// No description provided for @groupDetailTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupDetailTabMembers;

  /// No description provided for @groupDetailTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get groupDetailTabActivity;

  /// No description provided for @groupDetailNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet.'**
  String get groupDetailNoExpenses;

  /// No description provided for @groupDetailAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get groupDetailAddExpense;

  /// No description provided for @groupDetailSettleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get groupDetailSettleUp;

  /// No description provided for @groupDetailSettings.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupDetailSettings;

  /// No description provided for @groupDetailSimplifiedDebts.
  ///
  /// In en, this message translates to:
  /// **'Simplified debts'**
  String get groupDetailSimplifiedDebts;

  /// No description provided for @groupDetailNoDebts.
  ///
  /// In en, this message translates to:
  /// **'Everyone is settled!'**
  String get groupDetailNoDebts;

  /// No description provided for @groupDetailOwes.
  ///
  /// In en, this message translates to:
  /// **'{payer} owes {amount} to {receiver}'**
  String groupDetailOwes(String payer, String amount, String receiver);

  /// No description provided for @groupDetailRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupDetailRoleAdmin;

  /// No description provided for @groupDetailRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupDetailRoleMember;

  /// No description provided for @groupDetailRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get groupDetailRoleViewer;

  /// No description provided for @groupMemberCurrentUserSuffix.
  ///
  /// In en, this message translates to:
  /// **'(You)'**
  String get groupMemberCurrentUserSuffix;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get groupSettingsDeleteGroup;

  /// No description provided for @groupSettingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group? This cannot be undone.'**
  String get groupSettingsDeleteConfirm;

  /// No description provided for @groupSettingsLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groupSettingsLeaveGroup;

  /// No description provided for @groupSettingsLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get groupSettingsLeaveConfirm;

  /// No description provided for @groupSettingsRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get groupSettingsRemoveMember;

  /// No description provided for @groupSettingsRemoveMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the group?'**
  String groupSettingsRemoveMemberConfirm(String name);

  /// No description provided for @groupSettingsChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get groupSettingsChangeRole;

  /// No description provided for @groupSettingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get groupSettingsSaveSuccess;

  /// No description provided for @groupSettingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get groupSettingsDangerZone;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get addExpenseTitle;

  /// No description provided for @addExpenseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get addExpenseAmountLabel;

  /// No description provided for @addExpenseAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get addExpenseAmountHint;

  /// No description provided for @addExpenseDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get addExpenseDescriptionLabel;

  /// No description provided for @addExpenseDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Dinner at the restaurant'**
  String get addExpenseDescriptionHint;

  /// No description provided for @addExpensePaidByLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get addExpensePaidByLabel;

  /// No description provided for @addExpenseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get addExpenseDateLabel;

  /// No description provided for @addExpenseCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addExpenseCategoryLabel;

  /// No description provided for @addExpenseSplitMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Split method'**
  String get addExpenseSplitMethodLabel;

  /// No description provided for @addExpenseSplitMethodEqual.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get addExpenseSplitMethodEqual;

  /// No description provided for @addExpenseSplitMethodExact.
  ///
  /// In en, this message translates to:
  /// **'Exact amounts'**
  String get addExpenseSplitMethodExact;

  /// No description provided for @addExpenseSplitMethodPercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get addExpenseSplitMethodPercentage;

  /// No description provided for @addExpenseSplitMethodShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get addExpenseSplitMethodShares;

  /// No description provided for @addExpenseReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Add receipt'**
  String get addExpenseReceiptLabel;

  /// No description provided for @addExpenseSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get addExpenseSaveButton;

  /// No description provided for @addExpenseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense added!'**
  String get addExpenseSuccess;

  /// No description provided for @addExpenseError.
  ///
  /// In en, this message translates to:
  /// **'Error saving. Try again.'**
  String get addExpenseError;

  /// No description provided for @addExpenseFriendLabel.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get addExpenseFriendLabel;

  /// No description provided for @addExpenseFriendHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the friend involved in this expense'**
  String get addExpenseFriendHint;

  /// No description provided for @addExpenseFriendRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a friend for this expense.'**
  String get addExpenseFriendRequired;

  /// No description provided for @addExpenseNoFriendsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Add a friend first to create a personal shared expense.'**
  String get addExpenseNoFriendsAvailable;

  /// No description provided for @addExpenseAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get addExpenseAmountInvalid;

  /// No description provided for @addExpenseSplitDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Split does not match the total amount.'**
  String get addExpenseSplitDoesNotMatch;

  /// No description provided for @addExpenseSplitAutoChip.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get addExpenseSplitAutoChip;

  /// No description provided for @addExpenseSplitTotalExact.
  ///
  /// In en, this message translates to:
  /// **'Total: {sum} / {total}'**
  String addExpenseSplitTotalExact(String sum, String total);

  /// No description provided for @addExpenseSplitTotalPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String addExpenseSplitTotalPercentage(String percentage);

  /// No description provided for @addExpenseCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get addExpenseCurrencyLabel;

  /// No description provided for @addExpenseConvertedPreview.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} {currency} in group currency'**
  String addExpenseConvertedPreview(String amount, String currency);

  /// No description provided for @categoryGeral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeral;

  /// No description provided for @categoryComida.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryComida;

  /// No description provided for @categoryTransporte.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransporte;

  /// No description provided for @categoryMoradia.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryMoradia;

  /// No description provided for @categoryLazer.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryLazer;

  /// No description provided for @categoryViagem.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryViagem;

  /// No description provided for @categoryUtilidades.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilidades;

  /// No description provided for @expenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get expenseDetailTitle;

  /// No description provided for @expenseDetailPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String expenseDetailPaidBy(String name);

  /// No description provided for @expenseDetailSplitBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get expenseDetailSplitBreakdown;

  /// No description provided for @expenseDetailReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get expenseDetailReceipts;

  /// No description provided for @expenseDetailNoReceipts.
  ///
  /// In en, this message translates to:
  /// **'No receipts attached.'**
  String get expenseDetailNoReceipts;

  /// No description provided for @expenseDetailEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get expenseDetailEditButton;

  /// No description provided for @expenseDetailEditComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Editing is not available yet.'**
  String get expenseDetailEditComingSoon;

  /// No description provided for @expenseDetailDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expenseDetailDeleteButton;

  /// No description provided for @expenseDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense? This cannot be undone.'**
  String get expenseDetailDeleteConfirm;

  /// No description provided for @expenseDetailDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted.'**
  String get expenseDetailDeleteSuccess;

  /// No description provided for @expenseDetailOwes.
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}'**
  String expenseDetailOwes(String name, String amount);

  /// No description provided for @expenseDetailSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get expenseDetailSettled;

  /// No description provided for @expenseDetailLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified: {date}'**
  String expenseDetailLastModified(String date);

  /// No description provided for @settleUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUpTitle;

  /// No description provided for @settleUpPayerLabel.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get settleUpPayerLabel;

  /// No description provided for @settleUpReceiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay to'**
  String get settleUpReceiverLabel;

  /// No description provided for @settleUpAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get settleUpAmountLabel;

  /// No description provided for @settleUpNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get settleUpNoteLabel;

  /// No description provided for @settleUpNoteHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Rent split'**
  String get settleUpNoteHint;

  /// No description provided for @settleUpRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get settleUpRecordButton;

  /// No description provided for @settleUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded! Awaiting confirmation.'**
  String get settleUpSuccess;

  /// No description provided for @settleUpError.
  ///
  /// In en, this message translates to:
  /// **'Error recording payment.'**
  String get settleUpError;

  /// No description provided for @settleUpConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt'**
  String get settleUpConfirmButton;

  /// No description provided for @settleUpDisputeButton.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get settleUpDisputeButton;

  /// No description provided for @settleUpDisputeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Dispute this payment?'**
  String get settleUpDisputeConfirm;

  /// No description provided for @settleUpAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get settleUpAwaitingConfirmation;

  /// No description provided for @settleUpConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get settleUpConfirmed;

  /// No description provided for @settleUpDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get settleUpDisputed;

  /// No description provided for @settleUpSuggestedAmount.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {amount}'**
  String settleUpSuggestedAmount(String amount);

  /// No description provided for @settleUpPaymentProofSection.
  ///
  /// In en, this message translates to:
  /// **'Payment proof (optional)'**
  String get settleUpPaymentProofSection;

  /// No description provided for @settleUpAddProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Add proof'**
  String get settleUpAddProofLabel;

  /// No description provided for @settleUpProofUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload payment proof.'**
  String get settleUpProofUploadError;

  /// No description provided for @pendingSettlementYouPaidBeforeAmount.
  ///
  /// In en, this message translates to:
  /// **'You paid '**
  String get pendingSettlementYouPaidBeforeAmount;

  /// No description provided for @pendingSettlementYouPaidAfterAmount.
  ///
  /// In en, this message translates to:
  /// **' to {receiverName}'**
  String pendingSettlementYouPaidAfterAmount(String receiverName);

  /// No description provided for @pendingSettlementReceivedBeforeAmount.
  ///
  /// In en, this message translates to:
  /// **'{payerName} sent you '**
  String pendingSettlementReceivedBeforeAmount(String payerName);

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Invite someone!'**
  String get friendsEmpty;

  /// No description provided for @friendsInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Invite friend'**
  String get friendsInviteButton;

  /// No description provided for @friendsOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String friendsOwes(String amount);

  /// No description provided for @friendsOwed.
  ///
  /// In en, this message translates to:
  /// **'Owes you {amount}'**
  String friendsOwed(String amount);

  /// No description provided for @friendsEven.
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get friendsEven;

  /// No description provided for @friendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get friendsSearchHint;

  /// No description provided for @friendInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friend'**
  String get friendInviteTitle;

  /// No description provided for @friendInviteBody.
  ///
  /// In en, this message translates to:
  /// **'We create a unique link. Share it in any app—the other person opens it, signs in, and accepts.'**
  String get friendInviteBody;

  /// No description provided for @friendInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Generate invite link'**
  String get friendInviteButton;

  /// No description provided for @friendInviteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get friendInviteSuccess;

  /// No description provided for @friendInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied!'**
  String get friendInviteLinkCopied;

  /// No description provided for @friendAcceptInviteButton.
  ///
  /// In en, this message translates to:
  /// **'Accept invite'**
  String get friendAcceptInviteButton;

  /// No description provided for @friendAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invite accepted! You are now friends.'**
  String get friendAcceptSuccess;

  /// No description provided for @inviteGetTheAppHint.
  ///
  /// In en, this message translates to:
  /// **'Prefer the app? Get it here.'**
  String get inviteGetTheAppHint;

  /// No description provided for @inviteAppStoreButton.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get inviteAppStoreButton;

  /// No description provided for @invitePlayStoreButton.
  ///
  /// In en, this message translates to:
  /// **'Google Play'**
  String get invitePlayStoreButton;

  /// No description provided for @friendDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get friendDetailTitle;

  /// No description provided for @friendDetailNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance between you'**
  String get friendDetailNetBalance;

  /// No description provided for @friendDetailPendingSettlements.
  ///
  /// In en, this message translates to:
  /// **'Pending settlements'**
  String get friendDetailPendingSettlements;

  /// No description provided for @friendDetailSharedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Shared expenses'**
  String get friendDetailSharedExpenses;

  /// No description provided for @friendDetailSharedGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups in common'**
  String get friendDetailSharedGroups;

  /// No description provided for @friendDetailNoSharedExpenses.
  ///
  /// In en, this message translates to:
  /// **'No shared expenses.'**
  String get friendDetailNoSharedExpenses;

  /// No description provided for @friendDetailSettleUpButton.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get friendDetailSettleUpButton;

  /// No description provided for @friendDetailAddToGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get friendDetailAddToGroupButton;

  /// No description provided for @friendDetailNoEligibleGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups available for this friend.'**
  String get friendDetailNoEligibleGroups;

  /// No description provided for @friendDetailAddedToGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'{friendName} was added to {groupName}.'**
  String friendDetailAddedToGroupSuccess(String friendName, String groupName);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Managed by Google'**
  String get profileEmailReadOnly;

  /// No description provided for @profileDefaultCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get profileDefaultCurrencyLabel;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveButton;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileSaveSuccess;

  /// No description provided for @profileAvatarChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileAvatarChangeButton;

  /// No description provided for @profileSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutButton;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileDeleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get profileDeleteAccountButton;

  /// No description provided for @profileDeleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccountConfirmTitle;

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and cannot be undone. Continue?'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileDeleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get profileDeleteAccountSuccess;

  /// No description provided for @profileNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsSection;

  /// No description provided for @profilePushExpenseCreated.
  ///
  /// In en, this message translates to:
  /// **'New expense added'**
  String get profilePushExpenseCreated;

  /// No description provided for @profilePushSettlementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get profilePushSettlementRecorded;

  /// No description provided for @profilePushGroupInvitation.
  ///
  /// In en, this message translates to:
  /// **'Group invitation'**
  String get profilePushGroupInvitation;

  /// No description provided for @profileEmailExpenseCreated.
  ///
  /// In en, this message translates to:
  /// **'Email: new expense'**
  String get profileEmailExpenseCreated;

  /// No description provided for @profileEmailSettlementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Email: payment recorded'**
  String get profileEmailSettlementRecorded;

  /// No description provided for @profileAdFreeSection.
  ///
  /// In en, this message translates to:
  /// **'Ad-free plan'**
  String get profileAdFreeSection;

  /// No description provided for @profileAdFreeActive.
  ///
  /// In en, this message translates to:
  /// **'Plan active — thank you for your support!'**
  String get profileAdFreeActive;

  /// No description provided for @profileAdFreeExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String profileAdFreeExpires(String date);

  /// No description provided for @profileAdFreeMonthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get profileAdFreeMonthlyLabel;

  /// No description provided for @profileAdFreeYearlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get profileAdFreeYearlyLabel;

  /// No description provided for @profileAdFreePlanExpires.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String profileAdFreePlanExpires(String date);

  /// No description provided for @profileUpgradeMonthlyButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to monthly plan'**
  String get profileUpgradeMonthlyButton;

  /// No description provided for @profileUpgradeYearlyButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to yearly plan'**
  String get profileUpgradeYearlyButton;

  /// No description provided for @profileUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get profileUpgradeButton;

  /// No description provided for @profileManageSubscriptionButton.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get profileManageSubscriptionButton;

  /// No description provided for @profileExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get profileExportButton;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportTitle;

  /// No description provided for @exportDateFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get exportDateFromLabel;

  /// No description provided for @exportDateToLabel.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get exportDateToLabel;

  /// No description provided for @exportGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get exportGroupLabel;

  /// No description provided for @exportAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get exportAllGroups;

  /// No description provided for @exportGroupAll.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get exportGroupAll;

  /// No description provided for @exportShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get exportShareButton;

  /// No description provided for @exportGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get exportGenerateButton;

  /// No description provided for @exportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get exportGenerating;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully!'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Error generating report. Try again.'**
  String get exportError;

  /// No description provided for @sectionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section. Try again.'**
  String get sectionLoadError;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Check your connection and try again.'**
  String get profileLoadError;

  /// No description provided for @profileAdsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription status.'**
  String get profileAdsLoadError;

  /// No description provided for @exportPdfDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Rachae - expense report'**
  String get exportPdfDocumentTitle;

  /// No description provided for @exportPdfEmptyReport.
  ///
  /// In en, this message translates to:
  /// **'No data for the selected filters.'**
  String get exportPdfEmptyReport;

  /// No description provided for @exportPdfPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {fromDate} - {toDate}'**
  String exportPdfPeriod(String fromDate, String toDate);

  /// No description provided for @exportPdfTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Group total spent'**
  String get exportPdfTotalSpent;

  /// No description provided for @exportPdfPerPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Per person (paid / owed / net)'**
  String get exportPdfPerPersonTitle;

  /// No description provided for @exportPdfColumnPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get exportPdfColumnPerson;

  /// No description provided for @exportPdfColumnPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get exportPdfColumnPaid;

  /// No description provided for @exportPdfColumnOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get exportPdfColumnOwed;

  /// No description provided for @exportPdfColumnNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get exportPdfColumnNet;

  /// No description provided for @exportPdfExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense line items'**
  String get exportPdfExpensesTitle;

  /// No description provided for @exportPdfNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get exportPdfNoExpenses;

  /// No description provided for @exportPdfExpenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get exportPdfExpenseDescription;

  /// No description provided for @exportPdfExpenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportPdfExpenseAmount;

  /// No description provided for @exportPdfExpenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportPdfExpenseDate;

  /// No description provided for @exportPdfExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get exportPdfExpenseCategory;

  /// No description provided for @exportPdfSettlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlement history'**
  String get exportPdfSettlementsTitle;

  /// No description provided for @exportPdfNoSettlements.
  ///
  /// In en, this message translates to:
  /// **'No settlements in this period.'**
  String get exportPdfNoSettlements;

  /// No description provided for @exportPdfSettlementPayer.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get exportPdfSettlementPayer;

  /// No description provided for @exportPdfSettlementReceiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get exportPdfSettlementReceiver;

  /// No description provided for @exportPdfSettlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportPdfSettlementAmount;

  /// No description provided for @exportPdfSettlementDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportPdfSettlementDate;

  /// No description provided for @adBannerFallback.
  ///
  /// In en, this message translates to:
  /// **''**
  String get adBannerFallback;

  /// No description provided for @adFreeUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get adFreeUpgradeTitle;

  /// No description provided for @adFreeUpgradeDescription.
  ///
  /// In en, this message translates to:
  /// **'Enjoy Rachae without interruptions. A fair price, no tracking.'**
  String get adFreeUpgradeDescription;

  /// No description provided for @adFreeMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get adFreeMonthlyPlan;

  /// No description provided for @adFreeYearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get adFreeYearlyPlan;

  /// No description provided for @adFreeUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get adFreeUpgradeButton;

  /// No description provided for @adFreeCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime.'**
  String get adFreeCancelAnytime;

  /// No description provided for @stageOneReady.
  ///
  /// In en, this message translates to:
  /// **'Stage 1 foundation is ready.'**
  String get stageOneReady;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @authenticatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String authenticatedMessage(String email);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt': {
  switch (locale.countryCode) {
    case 'BR': return AppLocalizationsPtBr();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
