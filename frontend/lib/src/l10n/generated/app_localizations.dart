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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Rachae'**
  String get appTitle;

  /// No description provided for @loadingLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Carregando...'**
  String get loadingLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In pt_BR, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get errorGeneric;

  /// No description provided for @retryLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tentar novamente'**
  String get retryLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancelar'**
  String get cancelLabel;

  /// No description provided for @saveLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get saveLabel;

  /// No description provided for @editLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir'**
  String get deleteLabel;

  /// No description provided for @confirmLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Confirmar'**
  String get confirmLabel;

  /// No description provided for @closeLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Fechar'**
  String get closeLabel;

  /// No description provided for @backLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Voltar'**
  String get backLabel;

  /// No description provided for @doneLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Concluído'**
  String get doneLabel;

  /// No description provided for @yesLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sim'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não'**
  String get noLabel;

  /// No description provided for @searchLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar'**
  String get searchLabel;

  /// No description provided for @noResultsLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum resultado encontrado.'**
  String get noResultsLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Este campo é obrigatório.'**
  String get requiredFieldError;

  /// No description provided for @invalidAmountError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor inválido.'**
  String get invalidAmountError;

  /// No description provided for @unknownError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Erro desconhecido. Tente novamente.'**
  String get unknownError;

  /// No description provided for @networkError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem conexão. Verifique a internet.'**
  String get networkError;

  /// No description provided for @navDashboard.
  ///
  /// In pt_BR, this message translates to:
  /// **'Início'**
  String get navDashboard;

  /// No description provided for @navGroups.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grupos'**
  String get navGroups;

  /// No description provided for @navFriends.
  ///
  /// In pt_BR, this message translates to:
  /// **'Amigos'**
  String get navFriends;

  /// No description provided for @navProfile.
  ///
  /// In pt_BR, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @splashLoading.
  ///
  /// In pt_BR, this message translates to:
  /// **'Carregando...'**
  String get splashLoading;

  /// No description provided for @loginTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Divida despesas sem atrito'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entre com Google para continuar.'**
  String get loginSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar com Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In pt_BR, this message translates to:
  /// **'Continuar com Apple'**
  String get signInWithApple;

  /// No description provided for @unsupportedPlatformMessage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Login com Google disponível apenas em web e iOS.'**
  String get unsupportedPlatformMessage;

  /// No description provided for @oauthFailed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível iniciar o login. Tente novamente.'**
  String get oauthFailed;

  /// No description provided for @loginLoading.
  ///
  /// In pt_BR, this message translates to:
  /// **'Entrando...'**
  String get loginLoading;

  /// No description provided for @dashboardTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Início'**
  String get dashboardTitle;

  /// No description provided for @dashboardStubMessage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Painel completo na fase 18.'**
  String get dashboardStubMessage;

  /// No description provided for @dashboardYouOwe.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você deve'**
  String get dashboardYouOwe;

  /// No description provided for @dashboardYouAreOwed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Te devem'**
  String get dashboardYouAreOwed;

  /// No description provided for @dashboardNetBalance.
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldo líquido'**
  String get dashboardNetBalance;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In pt_BR, this message translates to:
  /// **'Atividade recente'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma atividade ainda.'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardActivityEndOfList.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não há mais atividades.'**
  String get dashboardActivityEndOfList;

  /// No description provided for @dashboardAddExpense.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar despesa'**
  String get dashboardAddExpense;

  /// No description provided for @dashboardShortcutPendingApprovals.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamentos pendentes para aprovar'**
  String get dashboardShortcutPendingApprovals;

  /// No description provided for @dashboardShortcutOwedToYou.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quem te deve'**
  String get dashboardShortcutOwedToYou;

  /// No description provided for @dashboardShortcutPendingSettlements.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertos pendentes'**
  String get dashboardShortcutPendingSettlements;

  /// No description provided for @dashboardPendingApprovalsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aprovações pendentes'**
  String get dashboardPendingApprovalsTitle;

  /// No description provided for @dashboardPendingApprovalsEmpty.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum pagamento aguardando sua confirmação.'**
  String get dashboardPendingApprovalsEmpty;

  /// No description provided for @dashboardOwedToYouTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quem te deve'**
  String get dashboardOwedToYouTitle;

  /// No description provided for @dashboardOwedToYouEmpty.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ninguém te deve nada no momento.'**
  String get dashboardOwedToYouEmpty;

  /// No description provided for @dashboardPendingSettlementsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertos pendentes'**
  String get dashboardPendingSettlementsTitle;

  /// No description provided for @dashboardPendingOutgoingSection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamentos que você registrou (aguardando confirmação)'**
  String get dashboardPendingOutgoingSection;

  /// No description provided for @dashboardYouOweSection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldos que você deve'**
  String get dashboardYouOweSection;

  /// No description provided for @dashboardYouOweEmpty.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você não deve nada a ninguém no momento.'**
  String get dashboardYouOweEmpty;

  /// No description provided for @dashboardYouOweSubtitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Toque para acertar'**
  String get dashboardYouOweSubtitle;

  /// No description provided for @dashboardPulledToRefresh.
  ///
  /// In pt_BR, this message translates to:
  /// **'Atualizado'**
  String get dashboardPulledToRefresh;

  /// No description provided for @activityExpenseAdded.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesa adicionada'**
  String get activityExpenseAdded;

  /// No description provided for @activitySettlementRecorded.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamento registrado'**
  String get activitySettlementRecorded;

  /// No description provided for @activitySettlementConfirmed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamento confirmado'**
  String get activitySettlementConfirmed;

  /// No description provided for @activityPaidBy.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pago por {name}'**
  String activityPaidBy(String name);

  /// No description provided for @activitySourcePersonal.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pessoal'**
  String get activitySourcePersonal;

  /// No description provided for @activityYouPaid.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você pagou'**
  String get activityYouPaid;

  /// No description provided for @activityAwaitingConfirmation.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aguardando confirmação'**
  String get activityAwaitingConfirmation;

  /// No description provided for @groupsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grupos'**
  String get groupsTitle;

  /// No description provided for @groupsEmpty.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum grupo ainda. Crie um!'**
  String get groupsEmpty;

  /// No description provided for @groupsCreateFab.
  ///
  /// In pt_BR, this message translates to:
  /// **'Novo grupo'**
  String get groupsCreateFab;

  /// No description provided for @groupMemberCount.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count} membros'**
  String groupMemberCount(int count);

  /// No description provided for @groupYourBalance.
  ///
  /// In pt_BR, this message translates to:
  /// **'Seu saldo'**
  String get groupYourBalance;

  /// No description provided for @groupBalancePositive.
  ///
  /// In pt_BR, this message translates to:
  /// **'Te devem R\$ {amount}'**
  String groupBalancePositive(String amount);

  /// No description provided for @groupBalanceNegative.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você deve R\$ {amount}'**
  String groupBalanceNegative(String amount);

  /// No description provided for @groupBalanceZero.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quitado'**
  String get groupBalanceZero;

  /// No description provided for @createGroupTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Novo grupo'**
  String get createGroupTitle;

  /// No description provided for @createGroupNameLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome do grupo'**
  String get createGroupNameLabel;

  /// No description provided for @createGroupNameHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ex: Viagem para o Rio'**
  String get createGroupNameHint;

  /// No description provided for @createGroupTypeLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tipo'**
  String get createGroupTypeLabel;

  /// No description provided for @createGroupTypeHome.
  ///
  /// In pt_BR, this message translates to:
  /// **'Casa'**
  String get createGroupTypeHome;

  /// No description provided for @createGroupTypeTrip.
  ///
  /// In pt_BR, this message translates to:
  /// **'Viagem'**
  String get createGroupTypeTrip;

  /// No description provided for @createGroupTypeCouple.
  ///
  /// In pt_BR, this message translates to:
  /// **'Casal'**
  String get createGroupTypeCouple;

  /// No description provided for @createGroupTypeOther.
  ///
  /// In pt_BR, this message translates to:
  /// **'Outro'**
  String get createGroupTypeOther;

  /// No description provided for @createGroupCurrencyLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Moeda do grupo'**
  String get createGroupCurrencyLabel;

  /// No description provided for @createGroupAddMembers.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar membros'**
  String get createGroupAddMembers;

  /// No description provided for @createGroupMemberSearchHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar por e-mail ou telefone'**
  String get createGroupMemberSearchHint;

  /// No description provided for @createGroupSimplifyDebts.
  ///
  /// In pt_BR, this message translates to:
  /// **'Simplificar dívidas automaticamente'**
  String get createGroupSimplifyDebts;

  /// No description provided for @createGroupButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Criar grupo'**
  String get createGroupButton;

  /// No description provided for @createGroupSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grupo criado com sucesso!'**
  String get createGroupSuccess;

  /// No description provided for @createGroupError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Erro ao criar grupo. Tente novamente.'**
  String get createGroupError;

  /// No description provided for @groupDetailTabExpenses.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesas'**
  String get groupDetailTabExpenses;

  /// No description provided for @groupDetailTabBalances.
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldos'**
  String get groupDetailTabBalances;

  /// No description provided for @groupDetailTabMembers.
  ///
  /// In pt_BR, this message translates to:
  /// **'Membros'**
  String get groupDetailTabMembers;

  /// No description provided for @groupDetailTabActivity.
  ///
  /// In pt_BR, this message translates to:
  /// **'Atividade'**
  String get groupDetailTabActivity;

  /// No description provided for @groupDetailNoExpenses.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma despesa ainda.'**
  String get groupDetailNoExpenses;

  /// No description provided for @groupDetailAddExpense.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar despesa'**
  String get groupDetailAddExpense;

  /// No description provided for @groupDetailSettleUp.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertar contas'**
  String get groupDetailSettleUp;

  /// No description provided for @groupDetailSettings.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações do grupo'**
  String get groupDetailSettings;

  /// No description provided for @groupDetailSimplifiedDebts.
  ///
  /// In pt_BR, this message translates to:
  /// **'Dívidas simplificadas'**
  String get groupDetailSimplifiedDebts;

  /// No description provided for @groupDetailNoDebts.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos estão quite!'**
  String get groupDetailNoDebts;

  /// No description provided for @groupDetailOwes.
  ///
  /// In pt_BR, this message translates to:
  /// **'{payer} deve {amount} para {receiver}'**
  String groupDetailOwes(String payer, String amount, String receiver);

  /// No description provided for @groupDetailRoleAdmin.
  ///
  /// In pt_BR, this message translates to:
  /// **'Admin'**
  String get groupDetailRoleAdmin;

  /// No description provided for @groupDetailRoleMember.
  ///
  /// In pt_BR, this message translates to:
  /// **'Membro'**
  String get groupDetailRoleMember;

  /// No description provided for @groupDetailRoleViewer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Visualizador'**
  String get groupDetailRoleViewer;

  /// No description provided for @groupMemberCurrentUserSuffix.
  ///
  /// In pt_BR, this message translates to:
  /// **'(Você)'**
  String get groupMemberCurrentUserSuffix;

  /// No description provided for @groupAddFriendsButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar amigos'**
  String get groupAddFriendsButton;

  /// No description provided for @groupAddMembersTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar amigos ao grupo'**
  String get groupAddMembersTitle;

  /// No description provided for @groupAddMembersNoFriends.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você ainda não tem amigos para adicionar.'**
  String get groupAddMembersNoFriends;

  /// No description provided for @groupAddMembersAllInGroup.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os seus amigos já estão neste grupo.'**
  String get groupAddMembersAllInGroup;

  /// No description provided for @groupAddMembersAddButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar'**
  String get groupAddMembersAddButton;

  /// No description provided for @groupAddMembersConfirmButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar ao grupo'**
  String get groupAddMembersConfirmButton;

  /// No description provided for @groupAddMembersConfirmWithCount.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar ({count})'**
  String groupAddMembersConfirmWithCount(int count);

  /// No description provided for @groupAddMembersAddedSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'{count} amigos adicionados ao grupo.'**
  String groupAddMembersAddedSuccess(int count);

  /// No description provided for @groupAddMembersPartialFailure.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível adicionar {failed} de {total}.'**
  String groupAddMembersPartialFailure(int failed, int total);

  /// No description provided for @groupAddMembersSelectAtLeastOne.
  ///
  /// In pt_BR, this message translates to:
  /// **'Selecione pelo menos um amigo.'**
  String get groupAddMembersSelectAtLeastOne;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações do grupo'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsDeleteGroup.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir grupo'**
  String get groupSettingsDeleteGroup;

  /// No description provided for @groupSettingsDeleteConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tem certeza que deseja excluir o grupo? Esta ação não pode ser desfeita.'**
  String get groupSettingsDeleteConfirm;

  /// No description provided for @groupSettingsLeaveGroup.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sair do grupo'**
  String get groupSettingsLeaveGroup;

  /// No description provided for @groupSettingsLeaveConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tem certeza que deseja sair do grupo?'**
  String get groupSettingsLeaveConfirm;

  /// No description provided for @groupSettingsRemoveMember.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover membro'**
  String get groupSettingsRemoveMember;

  /// No description provided for @groupSettingsRemoveMemberConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover {name} do grupo?'**
  String groupSettingsRemoveMemberConfirm(String name);

  /// No description provided for @groupSettingsChangeRole.
  ///
  /// In pt_BR, this message translates to:
  /// **'Alterar função'**
  String get groupSettingsChangeRole;

  /// No description provided for @groupSettingsSaveSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Configurações salvas.'**
  String get groupSettingsSaveSuccess;

  /// No description provided for @groupSettingsDangerZone.
  ///
  /// In pt_BR, this message translates to:
  /// **'Zona de perigo'**
  String get groupSettingsDangerZone;

  /// No description provided for @addExpenseTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova despesa'**
  String get addExpenseTitle;

  /// No description provided for @addExpenseAmountLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get addExpenseAmountLabel;

  /// No description provided for @addExpenseAmountHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'0,00'**
  String get addExpenseAmountHint;

  /// No description provided for @addExpenseDescriptionLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descrição'**
  String get addExpenseDescriptionLabel;

  /// No description provided for @addExpenseDescriptionHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ex: Jantar no restaurante'**
  String get addExpenseDescriptionHint;

  /// No description provided for @addExpensePaidByLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pago por'**
  String get addExpensePaidByLabel;

  /// No description provided for @addExpenseDateLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Data'**
  String get addExpenseDateLabel;

  /// No description provided for @addExpenseCategoryLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Categoria'**
  String get addExpenseCategoryLabel;

  /// No description provided for @addExpenseSplitMethodLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Forma de divisão'**
  String get addExpenseSplitMethodLabel;

  /// No description provided for @addExpenseSplitMethodEqual.
  ///
  /// In pt_BR, this message translates to:
  /// **'Igualmente'**
  String get addExpenseSplitMethodEqual;

  /// No description provided for @addExpenseSplitMethodExact.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valores exatos'**
  String get addExpenseSplitMethodExact;

  /// No description provided for @addExpenseSplitMethodPercentage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Porcentagem'**
  String get addExpenseSplitMethodPercentage;

  /// No description provided for @addExpenseSplitMethodShares.
  ///
  /// In pt_BR, this message translates to:
  /// **'Partes'**
  String get addExpenseSplitMethodShares;

  /// No description provided for @addExpenseReceiptLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar recibo'**
  String get addExpenseReceiptLabel;

  /// No description provided for @addExpenseSaveButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar despesa'**
  String get addExpenseSaveButton;

  /// No description provided for @addExpenseSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesa adicionada!'**
  String get addExpenseSuccess;

  /// No description provided for @addExpenseError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Erro ao salvar. Tente novamente.'**
  String get addExpenseError;

  /// No description provided for @addExpenseTimeoutError.
  ///
  /// In pt_BR, this message translates to:
  /// **'A requisição demorou demais. Verifique sua conexão e tente novamente.'**
  String get addExpenseTimeoutError;

  /// No description provided for @addExpenseReceiptUploadPartialFailure.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesa salva, mas alguns comprovantes não foram enviados.'**
  String get addExpenseReceiptUploadPartialFailure;

  /// No description provided for @addExpenseFriendLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Amigo'**
  String get addExpenseFriendLabel;

  /// No description provided for @addExpenseFriendHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha o amigo envolvido nesta despesa'**
  String get addExpenseFriendHint;

  /// No description provided for @addExpenseFriendRequired.
  ///
  /// In pt_BR, this message translates to:
  /// **'Escolha um amigo para esta despesa.'**
  String get addExpenseFriendRequired;

  /// No description provided for @addExpenseNoFriendsAvailable.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicione um amigo primeiro para criar uma despesa pessoal compartilhada.'**
  String get addExpenseNoFriendsAvailable;

  /// No description provided for @addExpenseAmountInvalid.
  ///
  /// In pt_BR, this message translates to:
  /// **'Informe um valor maior que zero.'**
  String get addExpenseAmountInvalid;

  /// No description provided for @addExpenseSplitDoesNotMatch.
  ///
  /// In pt_BR, this message translates to:
  /// **'A divisão não bate com o valor total.'**
  String get addExpenseSplitDoesNotMatch;

  /// No description provided for @addExpenseSplitAutoChip.
  ///
  /// In pt_BR, this message translates to:
  /// **'Automático'**
  String get addExpenseSplitAutoChip;

  /// No description provided for @addExpenseSplitTotalExact.
  ///
  /// In pt_BR, this message translates to:
  /// **'Total: {sum} / {total}'**
  String addExpenseSplitTotalExact(String sum, String total);

  /// No description provided for @addExpenseSplitTotalPercentage.
  ///
  /// In pt_BR, this message translates to:
  /// **'{percentage}%'**
  String addExpenseSplitTotalPercentage(String percentage);

  /// No description provided for @addExpenseCurrencyLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Moeda'**
  String get addExpenseCurrencyLabel;

  /// No description provided for @addExpenseConvertedPreview.
  ///
  /// In pt_BR, this message translates to:
  /// **'≈ {amount} {currency} na moeda do grupo'**
  String addExpenseConvertedPreview(String amount, String currency);

  /// No description provided for @categoryGeral.
  ///
  /// In pt_BR, this message translates to:
  /// **'Geral'**
  String get categoryGeral;

  /// No description provided for @categoryComida.
  ///
  /// In pt_BR, this message translates to:
  /// **'Comida'**
  String get categoryComida;

  /// No description provided for @categoryTransporte.
  ///
  /// In pt_BR, this message translates to:
  /// **'Transporte'**
  String get categoryTransporte;

  /// No description provided for @categoryMoradia.
  ///
  /// In pt_BR, this message translates to:
  /// **'Moradia'**
  String get categoryMoradia;

  /// No description provided for @categoryLazer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Lazer'**
  String get categoryLazer;

  /// No description provided for @categoryViagem.
  ///
  /// In pt_BR, this message translates to:
  /// **'Viagem'**
  String get categoryViagem;

  /// No description provided for @categoryUtilidades.
  ///
  /// In pt_BR, this message translates to:
  /// **'Utilidades'**
  String get categoryUtilidades;

  /// No description provided for @expenseDetailTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detalhes da despesa'**
  String get expenseDetailTitle;

  /// No description provided for @expenseDetailPaidBy.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pago por {name}'**
  String expenseDetailPaidBy(String name);

  /// No description provided for @expenseDetailSplitBreakdown.
  ///
  /// In pt_BR, this message translates to:
  /// **'Divisão'**
  String get expenseDetailSplitBreakdown;

  /// No description provided for @expenseDetailReceipts.
  ///
  /// In pt_BR, this message translates to:
  /// **'Recibos'**
  String get expenseDetailReceipts;

  /// No description provided for @expenseDetailNoReceipts.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum recibo anexado.'**
  String get expenseDetailNoReceipts;

  /// No description provided for @expenseDetailEditButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Editar'**
  String get expenseDetailEditButton;

  /// No description provided for @expenseDetailEditComingSoon.
  ///
  /// In pt_BR, this message translates to:
  /// **'Edição em breve.'**
  String get expenseDetailEditComingSoon;

  /// No description provided for @expenseDetailDeleteButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir'**
  String get expenseDetailDeleteButton;

  /// No description provided for @expenseDetailDeleteConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir esta despesa? Esta ação não pode ser desfeita.'**
  String get expenseDetailDeleteConfirm;

  /// No description provided for @expenseDetailDeleteSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesa excluída.'**
  String get expenseDetailDeleteSuccess;

  /// No description provided for @expenseDetailOwes.
  ///
  /// In pt_BR, this message translates to:
  /// **'{name} deve {amount}'**
  String expenseDetailOwes(String name, String amount);

  /// No description provided for @expenseDetailSettled.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertado'**
  String get expenseDetailSettled;

  /// No description provided for @expenseDetailLastModified.
  ///
  /// In pt_BR, this message translates to:
  /// **'Última modificação: {date}'**
  String expenseDetailLastModified(String date);

  /// No description provided for @settleUpTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertar contas'**
  String get settleUpTitle;

  /// No description provided for @settleUpPayerLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'De:'**
  String get settleUpPayerLabel;

  /// No description provided for @settleUpReceiverLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagar para'**
  String get settleUpReceiverLabel;

  /// No description provided for @settleUpAmountLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get settleUpAmountLabel;

  /// No description provided for @settleUpNoteLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nota (opcional)'**
  String get settleUpNoteLabel;

  /// No description provided for @settleUpNoteHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ex: Divisão do aluguel'**
  String get settleUpNoteHint;

  /// No description provided for @settleUpRecordButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Registrar pagamento'**
  String get settleUpRecordButton;

  /// No description provided for @settleUpSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamento registrado! Aguardando confirmação.'**
  String get settleUpSuccess;

  /// No description provided for @settleUpError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Erro ao registrar pagamento.'**
  String get settleUpError;

  /// No description provided for @settleUpConfirmButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Confirmar recebimento'**
  String get settleUpConfirmButton;

  /// No description provided for @settleUpDisputeButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Contestar'**
  String get settleUpDisputeButton;

  /// No description provided for @settleUpDisputeConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Contestar este pagamento?'**
  String get settleUpDisputeConfirm;

  /// No description provided for @settleUpAwaitingConfirmation.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aguardando confirmação'**
  String get settleUpAwaitingConfirmation;

  /// No description provided for @settleUpConfirmed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Confirmado'**
  String get settleUpConfirmed;

  /// No description provided for @settleUpDisputed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Contestado'**
  String get settleUpDisputed;

  /// No description provided for @settleUpSuggestedAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sugestão: {amount}'**
  String settleUpSuggestedAmount(String amount);

  /// No description provided for @settleUpPaymentProofSection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Comprovante de pagamento (opcional)'**
  String get settleUpPaymentProofSection;

  /// No description provided for @settleUpAddProofLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar comprovante'**
  String get settleUpAddProofLabel;

  /// No description provided for @settleUpProofUploadError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível enviar o comprovante.'**
  String get settleUpProofUploadError;

  /// No description provided for @settleUpOffsetButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compensar dívida (encontro de contas)'**
  String get settleUpOffsetButton;

  /// No description provided for @settleUpOffsetConfirmTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compensar esta dívida?'**
  String get settleUpOffsetConfirmTitle;

  /// No description provided for @settleUpOffsetConfirmMessage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Isso usa seu crédito existente com esta pessoa para quitar a dívida do grupo sem movimentar dinheiro de verdade.'**
  String get settleUpOffsetConfirmMessage;

  /// No description provided for @settleUpOffsetConfirmAction.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compensar'**
  String get settleUpOffsetConfirmAction;

  /// No description provided for @pendingSettlementYouPaidBeforeAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você pagou '**
  String get pendingSettlementYouPaidBeforeAmount;

  /// No description provided for @pendingSettlementYouPaidAfterAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **' para {receiverName}'**
  String pendingSettlementYouPaidAfterAmount(String receiverName);

  /// No description provided for @pendingSettlementReceivedBeforeAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **'{payerName} te enviou '**
  String pendingSettlementReceivedBeforeAmount(String payerName);

  /// No description provided for @friendsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Amigos'**
  String get friendsTitle;

  /// No description provided for @friendsEmpty.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum amigo ainda. Convide alguém!'**
  String get friendsEmpty;

  /// No description provided for @friendsInviteButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Convidar amigo'**
  String get friendsInviteButton;

  /// No description provided for @friendsOwes.
  ///
  /// In pt_BR, this message translates to:
  /// **'Deve {amount}'**
  String friendsOwes(String amount);

  /// No description provided for @friendsOwed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Te deve {amount}'**
  String friendsOwed(String amount);

  /// No description provided for @friendsEven.
  ///
  /// In pt_BR, this message translates to:
  /// **'Quite'**
  String get friendsEven;

  /// No description provided for @friendsSearchHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Buscar amigos'**
  String get friendsSearchHint;

  /// No description provided for @friendInviteTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Convidar amigo'**
  String get friendInviteTitle;

  /// No description provided for @friendInviteBody.
  ///
  /// In pt_BR, this message translates to:
  /// **'Geramos um link exclusivo. Envie por qualquer app para a pessoa entrar e aceitar depois de entrar na conta.'**
  String get friendInviteBody;

  /// No description provided for @friendInviteButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Gerar link de convite'**
  String get friendInviteButton;

  /// No description provided for @friendInviteSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Convite enviado!'**
  String get friendInviteSuccess;

  /// No description provided for @friendInviteLinkCopied.
  ///
  /// In pt_BR, this message translates to:
  /// **'Link de convite copiado!'**
  String get friendInviteLinkCopied;

  /// No description provided for @friendAcceptInviteButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aceitar convite'**
  String get friendAcceptInviteButton;

  /// No description provided for @friendAcceptSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Convite aceito! Agora vocês são amigos.'**
  String get friendAcceptSuccess;

  /// No description provided for @inviteGetTheAppHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Prefere o app? Baixe aqui.'**
  String get inviteGetTheAppHint;

  /// No description provided for @inviteAppStoreButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'App Store'**
  String get inviteAppStoreButton;

  /// No description provided for @invitePlayStoreButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Google Play'**
  String get invitePlayStoreButton;

  /// No description provided for @inviteOpenInAppHint.
  ///
  /// In pt_BR, this message translates to:
  /// **'Já tem o Rachae instalado? Abra o app para aceitar este convite.'**
  String get inviteOpenInAppHint;

  /// No description provided for @inviteOpenInAppButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Abrir no app'**
  String get inviteOpenInAppButton;

  /// No description provided for @friendDetailTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Detalhes'**
  String get friendDetailTitle;

  /// No description provided for @friendDetailNetBalance.
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldo entre vocês'**
  String get friendDetailNetBalance;

  /// No description provided for @friendDetailPendingSettlements.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamentos pendentes'**
  String get friendDetailPendingSettlements;

  /// No description provided for @friendDetailSharedExpenses.
  ///
  /// In pt_BR, this message translates to:
  /// **'Despesas compartilhadas'**
  String get friendDetailSharedExpenses;

  /// No description provided for @friendDetailSharedGroups.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grupos em comum'**
  String get friendDetailSharedGroups;

  /// No description provided for @friendDetailNoSharedExpenses.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma despesa compartilhada.'**
  String get friendDetailNoSharedExpenses;

  /// No description provided for @friendDetailSettleUpButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Acertar contas'**
  String get friendDetailSettleUpButton;

  /// No description provided for @friendDetailAddToGroupButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Adicionar ao grupo'**
  String get friendDetailAddToGroupButton;

  /// No description provided for @friendDetailNoEligibleGroups.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum grupo disponível para este amigo.'**
  String get friendDetailNoEligibleGroups;

  /// No description provided for @friendDetailAddedToGroupSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'{friendName} foi adicionado(a) a {groupName}!'**
  String friendDetailAddedToGroupSuccess(String friendName, String groupName);

  /// No description provided for @profileTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome de exibição'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail'**
  String get profileEmailLabel;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In pt_BR, this message translates to:
  /// **'Gerenciado pelo Google'**
  String get profileEmailReadOnly;

  /// No description provided for @profileDefaultCurrencyLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Moeda padrão'**
  String get profileDefaultCurrencyLabel;

  /// No description provided for @profileSaveButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar alterações'**
  String get profileSaveButton;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Perfil atualizado!'**
  String get profileSaveSuccess;

  /// No description provided for @profileAvatarChangeButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Alterar foto'**
  String get profileAvatarChangeButton;

  /// No description provided for @profileAvatarUploadError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível atualizar sua foto. Tente novamente.'**
  String get profileAvatarUploadError;

  /// No description provided for @profileSignOutButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sair'**
  String get profileSignOutButton;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Tem certeza que deseja sair?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileDeleteAccountButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir minha conta'**
  String get profileDeleteAccountButton;

  /// No description provided for @profileDeleteAccountConfirmTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir conta'**
  String get profileDeleteAccountConfirmTitle;

  /// No description provided for @profileDeleteAccountConfirm.
  ///
  /// In pt_BR, this message translates to:
  /// **'Excluir sua conta é permanente e não pode ser desfeito. Continuar?'**
  String get profileDeleteAccountConfirm;

  /// No description provided for @profileDeleteAccountSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Conta excluída.'**
  String get profileDeleteAccountSuccess;

  /// No description provided for @profileNotificationsSection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Notificações'**
  String get profileNotificationsSection;

  /// No description provided for @profilePushExpenseCreated.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nova despesa adicionada'**
  String get profilePushExpenseCreated;

  /// No description provided for @profilePushSettlementRecorded.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagamento registrado'**
  String get profilePushSettlementRecorded;

  /// No description provided for @profilePushGroupInvitation.
  ///
  /// In pt_BR, this message translates to:
  /// **'Convite de grupo'**
  String get profilePushGroupInvitation;

  /// No description provided for @profileEmailExpenseCreated.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail: nova despesa'**
  String get profileEmailExpenseCreated;

  /// No description provided for @profileEmailSettlementRecorded.
  ///
  /// In pt_BR, this message translates to:
  /// **'E-mail: pagamento registrado'**
  String get profileEmailSettlementRecorded;

  /// No description provided for @profileAdFreeSection.
  ///
  /// In pt_BR, this message translates to:
  /// **'Plano sem anúncios'**
  String get profileAdFreeSection;

  /// No description provided for @profileAdFreeActive.
  ///
  /// In pt_BR, this message translates to:
  /// **'Plano ativo — obrigado pelo suporte!'**
  String get profileAdFreeActive;

  /// No description provided for @profileAdFreeCanceled.
  ///
  /// In pt_BR, this message translates to:
  /// **'Plano cancelado — renovação automática desativada'**
  String get profileAdFreeCanceled;

  /// No description provided for @profileAdFreeAccessUntil.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você mantém o acesso sem anúncios até {date}'**
  String profileAdFreeAccessUntil(String date);

  /// No description provided for @profileAdFreeRenews.
  ///
  /// In pt_BR, this message translates to:
  /// **'Renova em {date}'**
  String profileAdFreeRenews(String date);

  /// No description provided for @profileAdFreeExpires.
  ///
  /// In pt_BR, this message translates to:
  /// **'Válido até {date}'**
  String profileAdFreeExpires(String date);

  /// No description provided for @profileAdFreeMonthlyLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mensal'**
  String get profileAdFreeMonthlyLabel;

  /// No description provided for @profileAdFreeYearlyLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anual'**
  String get profileAdFreeYearlyLabel;

  /// No description provided for @profileAdFreeLifetimeLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Vitalício'**
  String get profileAdFreeLifetimeLabel;

  /// No description provided for @profileAdFreePlanUnknown.
  ///
  /// In pt_BR, this message translates to:
  /// **'Assinatura ativa'**
  String get profileAdFreePlanUnknown;

  /// No description provided for @profileAdFreeCurrentPlanLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Plano atual: {planName}'**
  String profileAdFreeCurrentPlanLabel(String planName);

  /// No description provided for @profilePlanChangeStripePortalFootnote.
  ///
  /// In pt_BR, this message translates to:
  /// **'Use Gerenciar assinatura para mudar o plano. O Stripe aplica upgrades, downgrades e a cobrança conforme as regras da sua assinatura.'**
  String get profilePlanChangeStripePortalFootnote;

  /// No description provided for @profileIosSubscriptionChangeFootnote.
  ///
  /// In pt_BR, this message translates to:
  /// **'Para mudar o período de cobrança ou cancelar, use Gerenciar assinatura. A Apple faz upgrade/downgrade na mesma assinatura—evite comprar outro plano pelo paywall enquanto já estiver assinando.'**
  String get profileIosSubscriptionChangeFootnote;

  /// No description provided for @profileSeeRachaeProPlansButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Ver planos'**
  String get profileSeeRachaeProPlansButton;

  /// No description provided for @profileSubscriptionManagedElsewhere.
  ///
  /// In pt_BR, this message translates to:
  /// **'Alterações de assinatura não estão disponíveis no app. Entre em contato com o suporte se precisar de ajuda.'**
  String get profileSubscriptionManagedElsewhere;

  /// No description provided for @profileAdFreePlanExpires.
  ///
  /// In pt_BR, this message translates to:
  /// **'Válido até {date}'**
  String profileAdFreePlanExpires(String date);

  /// No description provided for @profileUpgradeMonthlyButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Assinar plano mensal'**
  String get profileUpgradeMonthlyButton;

  /// No description provided for @profileUpgradeYearlyButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Assinar plano anual'**
  String get profileUpgradeYearlyButton;

  /// No description provided for @profileUpgradeButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover anúncios'**
  String get profileUpgradeButton;

  /// No description provided for @profileManageSubscriptionButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Gerenciar assinatura'**
  String get profileManageSubscriptionButton;

  /// No description provided for @profileExportButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar dados'**
  String get profileExportButton;

  /// No description provided for @profileTermsOfUseButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Termos de Uso (EULA)'**
  String get profileTermsOfUseButton;

  /// No description provided for @profilePrivacyPolicyButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Política de Privacidade'**
  String get profilePrivacyPolicyButton;

  /// No description provided for @exportTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Exportar dados'**
  String get exportTitle;

  /// No description provided for @exportDateFromLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Data inicial'**
  String get exportDateFromLabel;

  /// No description provided for @exportDateToLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Data final'**
  String get exportDateToLabel;

  /// No description provided for @exportGroupLabel.
  ///
  /// In pt_BR, this message translates to:
  /// **'Grupo (opcional)'**
  String get exportGroupLabel;

  /// No description provided for @exportAllGroups.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os grupos'**
  String get exportAllGroups;

  /// No description provided for @exportGroupAll.
  ///
  /// In pt_BR, this message translates to:
  /// **'Todos os grupos'**
  String get exportGroupAll;

  /// No description provided for @exportShareButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compartilhar PDF'**
  String get exportShareButton;

  /// No description provided for @exportGenerateButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Gerar relatório'**
  String get exportGenerateButton;

  /// No description provided for @exportGenerating.
  ///
  /// In pt_BR, this message translates to:
  /// **'Gerando relatório...'**
  String get exportGenerating;

  /// No description provided for @exportSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Relatório gerado com sucesso!'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Erro ao gerar relatório. Tente novamente.'**
  String get exportError;

  /// No description provided for @sectionLoadError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível carregar esta seção. Tente novamente.'**
  String get sectionLoadError;

  /// No description provided for @profileLoadError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível carregar seu perfil. Verifique a conexão e tente novamente.'**
  String get profileLoadError;

  /// No description provided for @profileAdsLoadError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível carregar o status da assinatura.'**
  String get profileAdsLoadError;

  /// No description provided for @profileCheckoutSessionError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível iniciar o pagamento. Tente novamente.'**
  String get profileCheckoutSessionError;

  /// No description provided for @profileCheckoutAlreadySubscribed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você já tem uma assinatura ativa.'**
  String get profileCheckoutAlreadySubscribed;

  /// No description provided for @profileCheckoutCannotOpenUrl.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível abrir a página de pagamento. Tente novamente.'**
  String get profileCheckoutCannotOpenUrl;

  /// No description provided for @profileIapOfferingsUnavailable.
  ///
  /// In pt_BR, this message translates to:
  /// **'As opções de assinatura não estão disponíveis no momento. Tente mais tarde.'**
  String get profileIapOfferingsUnavailable;

  /// No description provided for @profileIapNotConfigured.
  ///
  /// In pt_BR, this message translates to:
  /// **'As compras no app ainda não foram configuradas. Cadastre os produtos na App Store Connect e vincule-os a um offering no dashboard do RevenueCat.'**
  String get profileIapNotConfigured;

  /// No description provided for @profileRevenueCatMissingApiKey.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compras no app não estão configuradas nesta build. Execute com REVENUECAT_IOS_API_KEY (ex.: flutter run --dart-define-from-file=../.env na pasta frontend) e configure produtos na App Store Connect e no RevenueCat.'**
  String get profileRevenueCatMissingApiKey;

  /// No description provided for @exportPdfDocumentTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Rachae - relatório de despesas'**
  String get exportPdfDocumentTitle;

  /// No description provided for @exportPdfEmptyReport.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sem dados para os filtros selecionados.'**
  String get exportPdfEmptyReport;

  /// No description provided for @exportPdfPeriod.
  ///
  /// In pt_BR, this message translates to:
  /// **'Período: {fromDate} - {toDate}'**
  String exportPdfPeriod(String fromDate, String toDate);

  /// No description provided for @exportPdfTotalSpent.
  ///
  /// In pt_BR, this message translates to:
  /// **'Total gasto do grupo'**
  String get exportPdfTotalSpent;

  /// No description provided for @exportPdfPerPersonTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Por pessoa (pago / devido / saldo)'**
  String get exportPdfPerPersonTitle;

  /// No description provided for @exportPdfColumnPerson.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pessoa'**
  String get exportPdfColumnPerson;

  /// No description provided for @exportPdfColumnPaid.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pago'**
  String get exportPdfColumnPaid;

  /// No description provided for @exportPdfColumnOwed.
  ///
  /// In pt_BR, this message translates to:
  /// **'Devido'**
  String get exportPdfColumnOwed;

  /// No description provided for @exportPdfColumnNet.
  ///
  /// In pt_BR, this message translates to:
  /// **'Saldo'**
  String get exportPdfColumnNet;

  /// No description provided for @exportPdfExpensesTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Linhas de despesa'**
  String get exportPdfExpensesTitle;

  /// No description provided for @exportPdfNoExpenses.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma despesa neste período.'**
  String get exportPdfNoExpenses;

  /// No description provided for @exportPdfExpenseDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Descrição'**
  String get exportPdfExpenseDescription;

  /// No description provided for @exportPdfExpenseAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get exportPdfExpenseAmount;

  /// No description provided for @exportPdfExpenseDate.
  ///
  /// In pt_BR, this message translates to:
  /// **'Data'**
  String get exportPdfExpenseDate;

  /// No description provided for @exportPdfExpenseCategory.
  ///
  /// In pt_BR, this message translates to:
  /// **'Categoria'**
  String get exportPdfExpenseCategory;

  /// No description provided for @exportPdfSettlementsTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Histórico de acertos'**
  String get exportPdfSettlementsTitle;

  /// No description provided for @exportPdfNoSettlements.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhum acerto neste período.'**
  String get exportPdfNoSettlements;

  /// No description provided for @exportPdfSettlementPayer.
  ///
  /// In pt_BR, this message translates to:
  /// **'Pagador'**
  String get exportPdfSettlementPayer;

  /// No description provided for @exportPdfSettlementReceiver.
  ///
  /// In pt_BR, this message translates to:
  /// **'Recebedor'**
  String get exportPdfSettlementReceiver;

  /// No description provided for @exportPdfSettlementAmount.
  ///
  /// In pt_BR, this message translates to:
  /// **'Valor'**
  String get exportPdfSettlementAmount;

  /// No description provided for @exportPdfSettlementDate.
  ///
  /// In pt_BR, this message translates to:
  /// **'Data'**
  String get exportPdfSettlementDate;

  /// No description provided for @adBannerFallback.
  ///
  /// In pt_BR, this message translates to:
  /// **''**
  String get adBannerFallback;

  /// No description provided for @adFreeUpgradeTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Remover anúncios'**
  String get adFreeUpgradeTitle;

  /// No description provided for @adFreeUpgradeDescription.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aproveite o Rachae sem interrupções. Um preço justo, sem rastreamento.'**
  String get adFreeUpgradeDescription;

  /// No description provided for @adFreeMonthlyPlan.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mensal'**
  String get adFreeMonthlyPlan;

  /// No description provided for @adFreeYearlyPlan.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anual'**
  String get adFreeYearlyPlan;

  /// No description provided for @adFreeMonthlyPlanOption.
  ///
  /// In pt_BR, this message translates to:
  /// **'Mensal (R\$ 4,99)'**
  String get adFreeMonthlyPlanOption;

  /// No description provided for @adFreeYearlyPlanOption.
  ///
  /// In pt_BR, this message translates to:
  /// **'Anual (R\$ 29,99)'**
  String get adFreeYearlyPlanOption;

  /// No description provided for @adFreeUpgradeButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Assinar'**
  String get adFreeUpgradeButton;

  /// No description provided for @adFreeCancelAnytime.
  ///
  /// In pt_BR, this message translates to:
  /// **'Cancele quando quiser.'**
  String get adFreeCancelAnytime;

  /// No description provided for @adFreeYearlySavingsBadge.
  ///
  /// In pt_BR, this message translates to:
  /// **'Economize {percent}%'**
  String adFreeYearlySavingsBadge(int percent);

  /// No description provided for @adFreeYearlyBestValueBadge.
  ///
  /// In pt_BR, this message translates to:
  /// **'Melhor custo-benefício'**
  String get adFreeYearlyBestValueBadge;

  /// No description provided for @adFreeSuccessTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Você está sem anúncios!'**
  String get adFreeSuccessTitle;

  /// No description provided for @adFreeSuccessMessage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Aproveite o Rachae sem interrupções. Obrigado pelo seu apoio!'**
  String get adFreeSuccessMessage;

  /// No description provided for @adFreeRestorePurchasesButton.
  ///
  /// In pt_BR, this message translates to:
  /// **'Restaurar compras'**
  String get adFreeRestorePurchasesButton;

  /// No description provided for @adFreeRestorePurchasesSuccess.
  ///
  /// In pt_BR, this message translates to:
  /// **'Compras restauradas — você está sem anúncios!'**
  String get adFreeRestorePurchasesSuccess;

  /// No description provided for @adFreeRestorePurchasesNotFound.
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma assinatura ativa encontrada para restaurar.'**
  String get adFreeRestorePurchasesNotFound;

  /// No description provided for @profileManageSubscriptionAppleUrlError.
  ///
  /// In pt_BR, this message translates to:
  /// **'Não foi possível abrir o gerenciamento de assinatura. Tente novamente.'**
  String get profileManageSubscriptionAppleUrlError;

  /// No description provided for @stageOneReady.
  ///
  /// In pt_BR, this message translates to:
  /// **'Base da fase 1 pronta.'**
  String get stageOneReady;

  /// No description provided for @homeTitle.
  ///
  /// In pt_BR, this message translates to:
  /// **'Início'**
  String get homeTitle;

  /// No description provided for @signOut.
  ///
  /// In pt_BR, this message translates to:
  /// **'Sair'**
  String get signOut;

  /// No description provided for @authenticatedMessage.
  ///
  /// In pt_BR, this message translates to:
  /// **'Logado como {email}'**
  String authenticatedMessage(String email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
