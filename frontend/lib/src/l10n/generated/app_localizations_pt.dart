// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Rachae';

  @override
  String get loadingLabel => 'Carregando...';

  @override
  String get errorGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get retryLabel => 'Tentar novamente';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get saveLabel => 'Salvar';

  @override
  String get editLabel => 'Editar';

  @override
  String get deleteLabel => 'Excluir';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get closeLabel => 'Fechar';

  @override
  String get backLabel => 'Voltar';

  @override
  String get doneLabel => 'Concluído';

  @override
  String get yesLabel => 'Sim';

  @override
  String get noLabel => 'Não';

  @override
  String get searchLabel => 'Buscar';

  @override
  String get noResultsLabel => 'Nenhum resultado encontrado.';

  @override
  String get requiredFieldError => 'Este campo é obrigatório.';

  @override
  String get invalidAmountError => 'Valor inválido.';

  @override
  String get unknownError => 'Erro desconhecido. Tente novamente.';

  @override
  String get networkError => 'Sem conexão. Verifique a internet.';

  @override
  String get navDashboard => 'Início';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navFriends => 'Amigos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get splashLoading => 'Carregando...';

  @override
  String get loginTitle => 'Divida despesas sem atrito';

  @override
  String get loginSubtitle => 'Entre com Google para continuar.';

  @override
  String get signInWithGoogle => 'Continuar com Google';

  @override
  String get signInWithApple => 'Continuar com Apple';

  @override
  String get unsupportedPlatformMessage =>
      'Login com Google disponível apenas em web e iOS.';

  @override
  String get oauthFailed =>
      'Não foi possível iniciar o login. Tente novamente.';

  @override
  String get loginLoading => 'Entrando...';

  @override
  String get dashboardTitle => 'Início';

  @override
  String get dashboardStubMessage => 'Painel completo na fase 18.';

  @override
  String get dashboardYouOwe => 'Você deve';

  @override
  String get dashboardYouAreOwed => 'Te devem';

  @override
  String get dashboardNetBalance => 'Saldo líquido';

  @override
  String get dashboardRecentActivity => 'Atividade recente';

  @override
  String get dashboardNoActivity => 'Nenhuma atividade ainda.';

  @override
  String get dashboardActivityEndOfList => 'Não há mais atividades.';

  @override
  String get dashboardAddExpense => 'Adicionar despesa';

  @override
  String get dashboardShortcutPendingApprovals =>
      'Pagamentos pendentes para aprovar';

  @override
  String get dashboardShortcutOwedToYou => 'Quem te deve';

  @override
  String get dashboardShortcutPendingSettlements => 'Acertos pendentes';

  @override
  String get dashboardPendingApprovalsTitle => 'Aprovações pendentes';

  @override
  String get dashboardPendingApprovalsEmpty =>
      'Nenhum pagamento aguardando sua confirmação.';

  @override
  String get dashboardOwedToYouTitle => 'Quem te deve';

  @override
  String get dashboardOwedToYouEmpty => 'Ninguém te deve nada no momento.';

  @override
  String get dashboardPendingSettlementsTitle => 'Acertos pendentes';

  @override
  String get dashboardPendingOutgoingSection =>
      'Pagamentos que você registrou (aguardando confirmação)';

  @override
  String get dashboardYouOweSection => 'Saldos que você deve';

  @override
  String get dashboardYouOweEmpty => 'Você não deve nada a ninguém no momento.';

  @override
  String get dashboardYouOweSubtitle => 'Toque para acertar';

  @override
  String get dashboardPulledToRefresh => 'Atualizado';

  @override
  String get activityExpenseAdded => 'Despesa adicionada';

  @override
  String get activitySettlementRecorded => 'Pagamento registrado';

  @override
  String get activitySettlementConfirmed => 'Pagamento confirmado';

  @override
  String activityPaidBy(String name) {
    return 'Pago por $name';
  }

  @override
  String get activitySourcePersonal => 'Pessoal';

  @override
  String get activityYouPaid => 'Você pagou';

  @override
  String get activityAwaitingConfirmation => 'Aguardando confirmação';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get groupsEmpty => 'Nenhum grupo ainda. Crie um!';

  @override
  String get groupsCreateFab => 'Novo grupo';

  @override
  String groupMemberCount(int count) {
    return '$count membros';
  }

  @override
  String get groupYourBalance => 'Seu saldo';

  @override
  String groupBalancePositive(String amount) {
    return 'Te devem R\$ $amount';
  }

  @override
  String groupBalanceNegative(String amount) {
    return 'Você deve R\$ $amount';
  }

  @override
  String get groupBalanceZero => 'Quitado';

  @override
  String get createGroupTitle => 'Novo grupo';

  @override
  String get createGroupNameLabel => 'Nome do grupo';

  @override
  String get createGroupNameHint => 'Ex: Viagem para o Rio';

  @override
  String get createGroupTypeLabel => 'Tipo';

  @override
  String get createGroupTypeHome => 'Casa';

  @override
  String get createGroupTypeTrip => 'Viagem';

  @override
  String get createGroupTypeCouple => 'Casal';

  @override
  String get createGroupTypeOther => 'Outro';

  @override
  String get createGroupCurrencyLabel => 'Moeda do grupo';

  @override
  String get createGroupAddMembers => 'Adicionar membros';

  @override
  String get createGroupMemberSearchHint => 'Buscar por e-mail ou telefone';

  @override
  String get createGroupSimplifyDebts => 'Simplificar dívidas automaticamente';

  @override
  String get createGroupButton => 'Criar grupo';

  @override
  String get createGroupSuccess => 'Grupo criado com sucesso!';

  @override
  String get createGroupError => 'Erro ao criar grupo. Tente novamente.';

  @override
  String get groupDetailTabExpenses => 'Despesas';

  @override
  String get groupDetailTabBalances => 'Saldos';

  @override
  String get groupDetailTabMembers => 'Membros';

  @override
  String get groupDetailTabActivity => 'Atividade';

  @override
  String get groupDetailNoExpenses => 'Nenhuma despesa ainda.';

  @override
  String get groupDetailAddExpense => 'Adicionar despesa';

  @override
  String get groupDetailSettleUp => 'Acertar contas';

  @override
  String get groupDetailSettings => 'Configurações do grupo';

  @override
  String get groupDetailSimplifiedDebts => 'Dívidas simplificadas';

  @override
  String get groupDetailNoDebts => 'Todos estão quite!';

  @override
  String groupDetailOwes(String payer, String amount, String receiver) {
    return '$payer deve $amount para $receiver';
  }

  @override
  String get groupDetailRoleAdmin => 'Admin';

  @override
  String get groupDetailRoleMember => 'Membro';

  @override
  String get groupDetailRoleViewer => 'Visualizador';

  @override
  String get groupMemberCurrentUserSuffix => '(Você)';

  @override
  String get groupAddFriendsButton => 'Adicionar amigos';

  @override
  String get groupAddMembersTitle => 'Adicionar amigos ao grupo';

  @override
  String get groupAddMembersNoFriends =>
      'Você ainda não tem amigos para adicionar.';

  @override
  String get groupAddMembersAllInGroup =>
      'Todos os seus amigos já estão neste grupo.';

  @override
  String get groupAddMembersAddButton => 'Adicionar';

  @override
  String get groupAddMembersConfirmButton => 'Adicionar ao grupo';

  @override
  String groupAddMembersConfirmWithCount(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String groupAddMembersAddedSuccess(int count) {
    return '$count amigos adicionados ao grupo.';
  }

  @override
  String groupAddMembersPartialFailure(int failed, int total) {
    return 'Não foi possível adicionar $failed de $total.';
  }

  @override
  String get groupAddMembersSelectAtLeastOne =>
      'Selecione pelo menos um amigo.';

  @override
  String get groupSettingsTitle => 'Configurações do grupo';

  @override
  String get groupSettingsDeleteGroup => 'Excluir grupo';

  @override
  String get groupSettingsDeleteConfirm =>
      'Tem certeza que deseja excluir o grupo? Esta ação não pode ser desfeita.';

  @override
  String get groupSettingsLeaveGroup => 'Sair do grupo';

  @override
  String get groupSettingsLeaveConfirm =>
      'Tem certeza que deseja sair do grupo?';

  @override
  String get groupSettingsRemoveMember => 'Remover membro';

  @override
  String groupSettingsRemoveMemberConfirm(String name) {
    return 'Remover $name do grupo?';
  }

  @override
  String get groupSettingsChangeRole => 'Alterar função';

  @override
  String get groupSettingsSaveSuccess => 'Configurações salvas.';

  @override
  String get groupSettingsDangerZone => 'Zona de perigo';

  @override
  String get addExpenseTitle => 'Nova despesa';

  @override
  String get addExpenseAmountLabel => 'Valor';

  @override
  String get addExpenseAmountHint => '0,00';

  @override
  String get addExpenseDescriptionLabel => 'Descrição';

  @override
  String get addExpenseDescriptionHint => 'Ex: Jantar no restaurante';

  @override
  String get addExpensePaidByLabel => 'Pago por';

  @override
  String get addExpenseDateLabel => 'Data';

  @override
  String get addExpenseCategoryLabel => 'Categoria';

  @override
  String get addExpenseSplitMethodLabel => 'Forma de divisão';

  @override
  String get addExpenseSplitMethodEqual => 'Igualmente';

  @override
  String get addExpenseSplitMethodExact => 'Valores exatos';

  @override
  String get addExpenseSplitMethodPercentage => 'Porcentagem';

  @override
  String get addExpenseSplitMethodShares => 'Partes';

  @override
  String get addExpenseReceiptLabel => 'Adicionar recibo';

  @override
  String get addExpenseSaveButton => 'Salvar despesa';

  @override
  String get addExpenseSuccess => 'Despesa adicionada!';

  @override
  String get addExpenseError => 'Erro ao salvar. Tente novamente.';

  @override
  String get addExpenseTimeoutError =>
      'A requisição demorou demais. Verifique sua conexão e tente novamente.';

  @override
  String get addExpenseReceiptUploadPartialFailure =>
      'Despesa salva, mas alguns comprovantes não foram enviados.';

  @override
  String get addExpenseFriendLabel => 'Amigo';

  @override
  String get addExpenseFriendHint => 'Escolha o amigo envolvido nesta despesa';

  @override
  String get addExpenseFriendRequired => 'Escolha um amigo para esta despesa.';

  @override
  String get addExpenseNoFriendsAvailable =>
      'Adicione um amigo primeiro para criar uma despesa pessoal compartilhada.';

  @override
  String get addExpenseAmountInvalid => 'Informe um valor maior que zero.';

  @override
  String get addExpenseSplitDoesNotMatch =>
      'A divisão não bate com o valor total.';

  @override
  String get addExpenseSplitAutoChip => 'Automático';

  @override
  String addExpenseSplitTotalExact(String sum, String total) {
    return 'Total: $sum / $total';
  }

  @override
  String addExpenseSplitTotalPercentage(String percentage) {
    return '$percentage%';
  }

  @override
  String get addExpenseCurrencyLabel => 'Moeda';

  @override
  String addExpenseConvertedPreview(String amount, String currency) {
    return '≈ $amount $currency na moeda do grupo';
  }

  @override
  String get categoryGeral => 'Geral';

  @override
  String get categoryComida => 'Comida';

  @override
  String get categoryTransporte => 'Transporte';

  @override
  String get categoryMoradia => 'Moradia';

  @override
  String get categoryLazer => 'Lazer';

  @override
  String get categoryViagem => 'Viagem';

  @override
  String get categoryUtilidades => 'Utilidades';

  @override
  String get expenseDetailTitle => 'Detalhes da despesa';

  @override
  String expenseDetailPaidBy(String name) {
    return 'Pago por $name';
  }

  @override
  String get expenseDetailSplitBreakdown => 'Divisão';

  @override
  String get expenseDetailReceipts => 'Recibos';

  @override
  String get expenseDetailNoReceipts => 'Nenhum recibo anexado.';

  @override
  String get expenseDetailEditButton => 'Editar';

  @override
  String get expenseDetailEditComingSoon => 'Edição em breve.';

  @override
  String get expenseDetailDeleteButton => 'Excluir';

  @override
  String get expenseDetailDeleteConfirm =>
      'Excluir esta despesa? Esta ação não pode ser desfeita.';

  @override
  String get expenseDetailDeleteSuccess => 'Despesa excluída.';

  @override
  String expenseDetailOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String get expenseDetailSettled => 'Acertado';

  @override
  String expenseDetailLastModified(String date) {
    return 'Última modificação: $date';
  }

  @override
  String get settleUpTitle => 'Acertar contas';

  @override
  String get settleUpPayerLabel => 'De:';

  @override
  String get settleUpReceiverLabel => 'Pagar para';

  @override
  String get settleUpAmountLabel => 'Valor';

  @override
  String get settleUpNoteLabel => 'Nota (opcional)';

  @override
  String get settleUpNoteHint => 'Ex: Divisão do aluguel';

  @override
  String get settleUpRecordButton => 'Registrar pagamento';

  @override
  String get settleUpSuccess => 'Pagamento registrado! Aguardando confirmação.';

  @override
  String get settleUpError => 'Erro ao registrar pagamento.';

  @override
  String get settleUpConfirmButton => 'Confirmar recebimento';

  @override
  String get settleUpDisputeButton => 'Contestar';

  @override
  String get settleUpDisputeConfirm => 'Contestar este pagamento?';

  @override
  String get settleUpAwaitingConfirmation => 'Aguardando confirmação';

  @override
  String get settleUpConfirmed => 'Confirmado';

  @override
  String get settleUpDisputed => 'Contestado';

  @override
  String settleUpSuggestedAmount(String amount) {
    return 'Sugestão: $amount';
  }

  @override
  String get settleUpPaymentProofSection =>
      'Comprovante de pagamento (opcional)';

  @override
  String get settleUpAddProofLabel => 'Adicionar comprovante';

  @override
  String get settleUpProofUploadError =>
      'Não foi possível enviar o comprovante.';

  @override
  String get settleUpOffsetButton => 'Compensar dívida (encontro de contas)';

  @override
  String get settleUpOffsetConfirmTitle => 'Compensar esta dívida?';

  @override
  String get settleUpOffsetConfirmMessage =>
      'Isso usa seu crédito existente com esta pessoa para quitar a dívida do grupo sem movimentar dinheiro de verdade.';

  @override
  String get settleUpOffsetConfirmAction => 'Compensar';

  @override
  String get pendingSettlementYouPaidBeforeAmount => 'Você pagou ';

  @override
  String pendingSettlementYouPaidAfterAmount(String receiverName) {
    return ' para $receiverName';
  }

  @override
  String pendingSettlementReceivedBeforeAmount(String payerName) {
    return '$payerName te enviou ';
  }

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsEmpty => 'Nenhum amigo ainda. Convide alguém!';

  @override
  String get friendsInviteButton => 'Convidar amigo';

  @override
  String friendsOwes(String amount) {
    return 'Deve $amount';
  }

  @override
  String friendsOwed(String amount) {
    return 'Te deve $amount';
  }

  @override
  String get friendsEven => 'Quite';

  @override
  String get friendsSearchHint => 'Buscar amigos';

  @override
  String get friendInviteTitle => 'Convidar amigo';

  @override
  String get friendInviteBody =>
      'Geramos um link exclusivo. Envie por qualquer app para a pessoa entrar e aceitar depois de entrar na conta.';

  @override
  String get friendInviteButton => 'Gerar link de convite';

  @override
  String get friendInviteSuccess => 'Convite enviado!';

  @override
  String get friendInviteLinkCopied => 'Link de convite copiado!';

  @override
  String get friendAcceptInviteButton => 'Aceitar convite';

  @override
  String get friendAcceptSuccess => 'Convite aceito! Agora vocês são amigos.';

  @override
  String get inviteGetTheAppHint => 'Prefere o app? Baixe aqui.';

  @override
  String get inviteAppStoreButton => 'App Store';

  @override
  String get invitePlayStoreButton => 'Google Play';

  @override
  String get inviteOpenInAppHint =>
      'Já tem o Rachae instalado? Abra o app para aceitar este convite.';

  @override
  String get inviteOpenInAppButton => 'Abrir no app';

  @override
  String get friendDetailTitle => 'Detalhes';

  @override
  String get friendDetailNetBalance => 'Saldo entre vocês';

  @override
  String get friendDetailPendingSettlements => 'Pagamentos pendentes';

  @override
  String get friendDetailSharedExpenses => 'Despesas compartilhadas';

  @override
  String get friendDetailSharedGroups => 'Grupos em comum';

  @override
  String get friendDetailNoSharedExpenses => 'Nenhuma despesa compartilhada.';

  @override
  String get friendDetailSettleUpButton => 'Acertar contas';

  @override
  String get friendDetailAddToGroupButton => 'Adicionar ao grupo';

  @override
  String get friendDetailNoEligibleGroups =>
      'Nenhum grupo disponível para este amigo.';

  @override
  String friendDetailAddedToGroupSuccess(String friendName, String groupName) {
    return '$friendName foi adicionado(a) a $groupName!';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileDisplayNameLabel => 'Nome de exibição';

  @override
  String get profileEmailLabel => 'E-mail';

  @override
  String get profileEmailReadOnly => 'Gerenciado pelo Google';

  @override
  String get profileDefaultCurrencyLabel => 'Moeda padrão';

  @override
  String get profileSaveButton => 'Salvar alterações';

  @override
  String get profileSaveSuccess => 'Perfil atualizado!';

  @override
  String get profileAvatarChangeButton => 'Alterar foto';

  @override
  String get profileSignOutButton => 'Sair';

  @override
  String get profileSignOutConfirm => 'Tem certeza que deseja sair?';

  @override
  String get profileDeleteAccountButton => 'Excluir minha conta';

  @override
  String get profileDeleteAccountConfirmTitle => 'Excluir conta';

  @override
  String get profileDeleteAccountConfirm =>
      'Excluir sua conta é permanente e não pode ser desfeito. Continuar?';

  @override
  String get profileDeleteAccountSuccess => 'Conta excluída.';

  @override
  String get profileNotificationsSection => 'Notificações';

  @override
  String get profilePushExpenseCreated => 'Nova despesa adicionada';

  @override
  String get profilePushSettlementRecorded => 'Pagamento registrado';

  @override
  String get profilePushGroupInvitation => 'Convite de grupo';

  @override
  String get profileEmailExpenseCreated => 'E-mail: nova despesa';

  @override
  String get profileEmailSettlementRecorded => 'E-mail: pagamento registrado';

  @override
  String get profileAdFreeSection => 'Plano sem anúncios';

  @override
  String get profileAdFreeActive => 'Plano ativo — obrigado pelo suporte!';

  @override
  String profileAdFreeExpires(String date) {
    return 'Válido até $date';
  }

  @override
  String get profileAdFreeMonthlyLabel => 'Mensal';

  @override
  String get profileAdFreeYearlyLabel => 'Anual';

  @override
  String get profileAdFreeLifetimeLabel => 'Vitalício';

  @override
  String get profileAdFreePlanUnknown => 'Assinatura ativa';

  @override
  String profileAdFreeCurrentPlanLabel(String planName) {
    return 'Plano atual: $planName';
  }

  @override
  String get profilePlanChangeStripePortalFootnote =>
      'Use Gerenciar assinatura para mudar o plano. O Stripe aplica upgrades, downgrades e a cobrança conforme as regras da sua assinatura.';

  @override
  String get profileIosSubscriptionChangeFootnote =>
      'Para mudar o período de cobrança ou cancelar, use Gerenciar assinatura. A Apple faz upgrade/downgrade na mesma assinatura—evite comprar outro plano pelo paywall enquanto já estiver assinando.';

  @override
  String get profileSeeRachaeProPlansButton => 'Ver planos';

  @override
  String get profileSubscriptionManagedElsewhere =>
      'Alterações de assinatura não estão disponíveis no app. Entre em contato com o suporte se precisar de ajuda.';

  @override
  String profileAdFreePlanExpires(String date) {
    return 'Válido até $date';
  }

  @override
  String get profileUpgradeMonthlyButton => 'Assinar plano mensal';

  @override
  String get profileUpgradeYearlyButton => 'Assinar plano anual';

  @override
  String get profileUpgradeButton => 'Remover anúncios';

  @override
  String get profileManageSubscriptionButton => 'Gerenciar assinatura';

  @override
  String get profileExportButton => 'Exportar dados';

  @override
  String get exportTitle => 'Exportar dados';

  @override
  String get exportDateFromLabel => 'Data inicial';

  @override
  String get exportDateToLabel => 'Data final';

  @override
  String get exportGroupLabel => 'Grupo (opcional)';

  @override
  String get exportAllGroups => 'Todos os grupos';

  @override
  String get exportGroupAll => 'Todos os grupos';

  @override
  String get exportShareButton => 'Compartilhar PDF';

  @override
  String get exportGenerateButton => 'Gerar relatório';

  @override
  String get exportGenerating => 'Gerando relatório...';

  @override
  String get exportSuccess => 'Relatório gerado com sucesso!';

  @override
  String get exportError => 'Erro ao gerar relatório. Tente novamente.';

  @override
  String get sectionLoadError =>
      'Não foi possível carregar esta seção. Tente novamente.';

  @override
  String get profileLoadError =>
      'Não foi possível carregar seu perfil. Verifique a conexão e tente novamente.';

  @override
  String get profileAdsLoadError =>
      'Não foi possível carregar o status da assinatura.';

  @override
  String get profileCheckoutSessionError =>
      'Não foi possível iniciar o pagamento. Tente novamente.';

  @override
  String get profileCheckoutAlreadySubscribed =>
      'Você já tem uma assinatura ativa.';

  @override
  String get profileCheckoutCannotOpenUrl =>
      'Não foi possível abrir a página de pagamento. Tente novamente.';

  @override
  String get profileIapOfferingsUnavailable =>
      'As opções de assinatura não estão disponíveis no momento. Tente mais tarde.';

  @override
  String get profileRevenueCatMissingApiKey =>
      'Compras no app não estão configuradas nesta build. Execute com REVENUECAT_IOS_API_KEY (ex.: flutter run --dart-define-from-file=../.env na pasta frontend) e configure produtos na App Store Connect e no RevenueCat.';

  @override
  String get exportPdfDocumentTitle => 'Rachae - relatório de despesas';

  @override
  String get exportPdfEmptyReport => 'Sem dados para os filtros selecionados.';

  @override
  String exportPdfPeriod(String fromDate, String toDate) {
    return 'Período: $fromDate - $toDate';
  }

  @override
  String get exportPdfTotalSpent => 'Total gasto do grupo';

  @override
  String get exportPdfPerPersonTitle => 'Por pessoa (pago / devido / saldo)';

  @override
  String get exportPdfColumnPerson => 'Pessoa';

  @override
  String get exportPdfColumnPaid => 'Pago';

  @override
  String get exportPdfColumnOwed => 'Devido';

  @override
  String get exportPdfColumnNet => 'Saldo';

  @override
  String get exportPdfExpensesTitle => 'Linhas de despesa';

  @override
  String get exportPdfNoExpenses => 'Nenhuma despesa neste período.';

  @override
  String get exportPdfExpenseDescription => 'Descrição';

  @override
  String get exportPdfExpenseAmount => 'Valor';

  @override
  String get exportPdfExpenseDate => 'Data';

  @override
  String get exportPdfExpenseCategory => 'Categoria';

  @override
  String get exportPdfSettlementsTitle => 'Histórico de acertos';

  @override
  String get exportPdfNoSettlements => 'Nenhum acerto neste período.';

  @override
  String get exportPdfSettlementPayer => 'Pagador';

  @override
  String get exportPdfSettlementReceiver => 'Recebedor';

  @override
  String get exportPdfSettlementAmount => 'Valor';

  @override
  String get exportPdfSettlementDate => 'Data';

  @override
  String get adBannerFallback => '';

  @override
  String get adFreeUpgradeTitle => 'Remover anúncios';

  @override
  String get adFreeUpgradeDescription =>
      'Aproveite o Rachae sem interrupções. Um preço justo, sem rastreamento.';

  @override
  String get adFreeMonthlyPlan => 'Mensal';

  @override
  String get adFreeYearlyPlan => 'Anual';

  @override
  String get adFreeMonthlyPlanOption => 'Mensal (R\$ 4,99)';

  @override
  String get adFreeYearlyPlanOption => 'Anual (R\$ 29,99)';

  @override
  String get adFreeUpgradeButton => 'Assinar';

  @override
  String get adFreeCancelAnytime => 'Cancele quando quiser.';

  @override
  String get stageOneReady => 'Base da fase 1 pronta.';

  @override
  String get homeTitle => 'Início';

  @override
  String get signOut => 'Sair';

  @override
  String authenticatedMessage(String email) {
    return 'Logado como $email';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Rachae';

  @override
  String get loadingLabel => 'Carregando...';

  @override
  String get errorGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get retryLabel => 'Tentar novamente';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get saveLabel => 'Salvar';

  @override
  String get editLabel => 'Editar';

  @override
  String get deleteLabel => 'Excluir';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get closeLabel => 'Fechar';

  @override
  String get backLabel => 'Voltar';

  @override
  String get doneLabel => 'Concluído';

  @override
  String get yesLabel => 'Sim';

  @override
  String get noLabel => 'Não';

  @override
  String get searchLabel => 'Buscar';

  @override
  String get noResultsLabel => 'Nenhum resultado encontrado.';

  @override
  String get requiredFieldError => 'Este campo é obrigatório.';

  @override
  String get invalidAmountError => 'Valor inválido.';

  @override
  String get unknownError => 'Erro desconhecido. Tente novamente.';

  @override
  String get networkError => 'Sem conexão. Verifique a internet.';

  @override
  String get navDashboard => 'Início';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navFriends => 'Amigos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get splashLoading => 'Carregando...';

  @override
  String get loginTitle => 'Divida despesas sem atrito';

  @override
  String get loginSubtitle => 'Entre com Google para continuar.';

  @override
  String get signInWithGoogle => 'Continuar com Google';

  @override
  String get signInWithApple => 'Continuar com Apple';

  @override
  String get unsupportedPlatformMessage =>
      'Login com Google disponível apenas em web e iOS.';

  @override
  String get oauthFailed =>
      'Não foi possível iniciar o login. Tente novamente.';

  @override
  String get loginLoading => 'Entrando...';

  @override
  String get dashboardTitle => 'Início';

  @override
  String get dashboardStubMessage => 'Painel completo na fase 18.';

  @override
  String get dashboardYouOwe => 'Você deve';

  @override
  String get dashboardYouAreOwed => 'Te devem';

  @override
  String get dashboardNetBalance => 'Saldo líquido';

  @override
  String get dashboardRecentActivity => 'Atividade recente';

  @override
  String get dashboardNoActivity => 'Nenhuma atividade ainda.';

  @override
  String get dashboardActivityEndOfList => 'Não há mais atividades.';

  @override
  String get dashboardAddExpense => 'Adicionar despesa';

  @override
  String get dashboardShortcutPendingApprovals =>
      'Pagamentos pendentes para aprovar';

  @override
  String get dashboardShortcutOwedToYou => 'Quem te deve';

  @override
  String get dashboardShortcutPendingSettlements => 'Acertos pendentes';

  @override
  String get dashboardPendingApprovalsTitle => 'Aprovações pendentes';

  @override
  String get dashboardPendingApprovalsEmpty =>
      'Nenhum pagamento aguardando sua confirmação.';

  @override
  String get dashboardOwedToYouTitle => 'Quem te deve';

  @override
  String get dashboardOwedToYouEmpty => 'Ninguém te deve nada no momento.';

  @override
  String get dashboardPendingSettlementsTitle => 'Acertos pendentes';

  @override
  String get dashboardPendingOutgoingSection =>
      'Pagamentos que você registrou (aguardando confirmação)';

  @override
  String get dashboardYouOweSection => 'Saldos que você deve';

  @override
  String get dashboardYouOweEmpty => 'Você não deve nada a ninguém no momento.';

  @override
  String get dashboardYouOweSubtitle => 'Toque para acertar';

  @override
  String get dashboardPulledToRefresh => 'Atualizado';

  @override
  String get activityExpenseAdded => 'Despesa adicionada';

  @override
  String get activitySettlementRecorded => 'Pagamento registrado';

  @override
  String get activitySettlementConfirmed => 'Pagamento confirmado';

  @override
  String activityPaidBy(String name) {
    return 'Pago por $name';
  }

  @override
  String get activitySourcePersonal => 'Pessoal';

  @override
  String get activityYouPaid => 'Você pagou';

  @override
  String get activityAwaitingConfirmation => 'Aguardando confirmação';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get groupsEmpty => 'Nenhum grupo ainda. Crie um!';

  @override
  String get groupsCreateFab => 'Novo grupo';

  @override
  String groupMemberCount(int count) {
    return '$count membros';
  }

  @override
  String get groupYourBalance => 'Seu saldo';

  @override
  String groupBalancePositive(String amount) {
    return 'Te devem R\$ $amount';
  }

  @override
  String groupBalanceNegative(String amount) {
    return 'Você deve R\$ $amount';
  }

  @override
  String get groupBalanceZero => 'Quitado';

  @override
  String get createGroupTitle => 'Novo grupo';

  @override
  String get createGroupNameLabel => 'Nome do grupo';

  @override
  String get createGroupNameHint => 'Ex: Viagem para o Rio';

  @override
  String get createGroupTypeLabel => 'Tipo';

  @override
  String get createGroupTypeHome => 'Casa';

  @override
  String get createGroupTypeTrip => 'Viagem';

  @override
  String get createGroupTypeCouple => 'Casal';

  @override
  String get createGroupTypeOther => 'Outro';

  @override
  String get createGroupCurrencyLabel => 'Moeda do grupo';

  @override
  String get createGroupAddMembers => 'Adicionar membros';

  @override
  String get createGroupMemberSearchHint => 'Buscar por e-mail ou telefone';

  @override
  String get createGroupSimplifyDebts => 'Simplificar dívidas automaticamente';

  @override
  String get createGroupButton => 'Criar grupo';

  @override
  String get createGroupSuccess => 'Grupo criado com sucesso!';

  @override
  String get createGroupError => 'Erro ao criar grupo. Tente novamente.';

  @override
  String get groupDetailTabExpenses => 'Despesas';

  @override
  String get groupDetailTabBalances => 'Saldos';

  @override
  String get groupDetailTabMembers => 'Membros';

  @override
  String get groupDetailTabActivity => 'Atividade';

  @override
  String get groupDetailNoExpenses => 'Nenhuma despesa ainda.';

  @override
  String get groupDetailAddExpense => 'Adicionar despesa';

  @override
  String get groupDetailSettleUp => 'Acertar contas';

  @override
  String get groupDetailSettings => 'Configurações do grupo';

  @override
  String get groupDetailSimplifiedDebts => 'Dívidas simplificadas';

  @override
  String get groupDetailNoDebts => 'Todos estão quite!';

  @override
  String groupDetailOwes(String payer, String amount, String receiver) {
    return '$payer deve $amount para $receiver';
  }

  @override
  String get groupDetailRoleAdmin => 'Admin';

  @override
  String get groupDetailRoleMember => 'Membro';

  @override
  String get groupDetailRoleViewer => 'Visualizador';

  @override
  String get groupMemberCurrentUserSuffix => '(Você)';

  @override
  String get groupAddFriendsButton => 'Adicionar amigos';

  @override
  String get groupAddMembersTitle => 'Adicionar amigos ao grupo';

  @override
  String get groupAddMembersNoFriends =>
      'Você ainda não tem amigos para adicionar.';

  @override
  String get groupAddMembersAllInGroup =>
      'Todos os seus amigos já estão neste grupo.';

  @override
  String get groupAddMembersAddButton => 'Adicionar';

  @override
  String get groupAddMembersConfirmButton => 'Adicionar ao grupo';

  @override
  String groupAddMembersConfirmWithCount(int count) {
    return 'Adicionar ($count)';
  }

  @override
  String groupAddMembersAddedSuccess(int count) {
    return '$count amigos adicionados ao grupo.';
  }

  @override
  String groupAddMembersPartialFailure(int failed, int total) {
    return 'Não foi possível adicionar $failed de $total.';
  }

  @override
  String get groupAddMembersSelectAtLeastOne =>
      'Selecione pelo menos um amigo.';

  @override
  String get groupSettingsTitle => 'Configurações do grupo';

  @override
  String get groupSettingsDeleteGroup => 'Excluir grupo';

  @override
  String get groupSettingsDeleteConfirm =>
      'Tem certeza que deseja excluir o grupo? Esta ação não pode ser desfeita.';

  @override
  String get groupSettingsLeaveGroup => 'Sair do grupo';

  @override
  String get groupSettingsLeaveConfirm =>
      'Tem certeza que deseja sair do grupo?';

  @override
  String get groupSettingsRemoveMember => 'Remover membro';

  @override
  String groupSettingsRemoveMemberConfirm(String name) {
    return 'Remover $name do grupo?';
  }

  @override
  String get groupSettingsChangeRole => 'Alterar função';

  @override
  String get groupSettingsSaveSuccess => 'Configurações salvas.';

  @override
  String get groupSettingsDangerZone => 'Zona de perigo';

  @override
  String get addExpenseTitle => 'Nova despesa';

  @override
  String get addExpenseAmountLabel => 'Valor';

  @override
  String get addExpenseAmountHint => '0,00';

  @override
  String get addExpenseDescriptionLabel => 'Descrição';

  @override
  String get addExpenseDescriptionHint => 'Ex: Jantar no restaurante';

  @override
  String get addExpensePaidByLabel => 'Pago por';

  @override
  String get addExpenseDateLabel => 'Data';

  @override
  String get addExpenseCategoryLabel => 'Categoria';

  @override
  String get addExpenseSplitMethodLabel => 'Forma de divisão';

  @override
  String get addExpenseSplitMethodEqual => 'Igualmente';

  @override
  String get addExpenseSplitMethodExact => 'Valores exatos';

  @override
  String get addExpenseSplitMethodPercentage => 'Porcentagem';

  @override
  String get addExpenseSplitMethodShares => 'Partes';

  @override
  String get addExpenseReceiptLabel => 'Adicionar recibo';

  @override
  String get addExpenseSaveButton => 'Salvar despesa';

  @override
  String get addExpenseSuccess => 'Despesa adicionada!';

  @override
  String get addExpenseError => 'Erro ao salvar. Tente novamente.';

  @override
  String get addExpenseTimeoutError =>
      'A requisição demorou demais. Verifique sua conexão e tente novamente.';

  @override
  String get addExpenseReceiptUploadPartialFailure =>
      'Despesa salva, mas alguns comprovantes não foram enviados.';

  @override
  String get addExpenseFriendLabel => 'Amigo';

  @override
  String get addExpenseFriendHint => 'Escolha o amigo envolvido nesta despesa';

  @override
  String get addExpenseFriendRequired => 'Escolha um amigo para esta despesa.';

  @override
  String get addExpenseNoFriendsAvailable =>
      'Adicione um amigo primeiro para criar uma despesa pessoal compartilhada.';

  @override
  String get addExpenseAmountInvalid => 'Informe um valor maior que zero.';

  @override
  String get addExpenseSplitDoesNotMatch =>
      'A divisão não bate com o valor total.';

  @override
  String get addExpenseSplitAutoChip => 'Automático';

  @override
  String addExpenseSplitTotalExact(String sum, String total) {
    return 'Total: $sum / $total';
  }

  @override
  String addExpenseSplitTotalPercentage(String percentage) {
    return '$percentage%';
  }

  @override
  String get addExpenseCurrencyLabel => 'Moeda';

  @override
  String addExpenseConvertedPreview(String amount, String currency) {
    return '≈ $amount $currency na moeda do grupo';
  }

  @override
  String get categoryGeral => 'Geral';

  @override
  String get categoryComida => 'Comida';

  @override
  String get categoryTransporte => 'Transporte';

  @override
  String get categoryMoradia => 'Moradia';

  @override
  String get categoryLazer => 'Lazer';

  @override
  String get categoryViagem => 'Viagem';

  @override
  String get categoryUtilidades => 'Utilidades';

  @override
  String get expenseDetailTitle => 'Detalhes da despesa';

  @override
  String expenseDetailPaidBy(String name) {
    return 'Pago por $name';
  }

  @override
  String get expenseDetailSplitBreakdown => 'Divisão';

  @override
  String get expenseDetailReceipts => 'Recibos';

  @override
  String get expenseDetailNoReceipts => 'Nenhum recibo anexado.';

  @override
  String get expenseDetailEditButton => 'Editar';

  @override
  String get expenseDetailEditComingSoon => 'Edição em breve.';

  @override
  String get expenseDetailDeleteButton => 'Excluir';

  @override
  String get expenseDetailDeleteConfirm =>
      'Excluir esta despesa? Esta ação não pode ser desfeita.';

  @override
  String get expenseDetailDeleteSuccess => 'Despesa excluída.';

  @override
  String expenseDetailOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String get expenseDetailSettled => 'Acertado';

  @override
  String expenseDetailLastModified(String date) {
    return 'Última modificação: $date';
  }

  @override
  String get settleUpTitle => 'Acertar contas';

  @override
  String get settleUpPayerLabel => 'De:';

  @override
  String get settleUpReceiverLabel => 'Pagar para';

  @override
  String get settleUpAmountLabel => 'Valor';

  @override
  String get settleUpNoteLabel => 'Nota (opcional)';

  @override
  String get settleUpNoteHint => 'Ex: Divisão do aluguel';

  @override
  String get settleUpRecordButton => 'Registrar pagamento';

  @override
  String get settleUpSuccess => 'Pagamento registrado! Aguardando confirmação.';

  @override
  String get settleUpError => 'Erro ao registrar pagamento.';

  @override
  String get settleUpConfirmButton => 'Confirmar recebimento';

  @override
  String get settleUpDisputeButton => 'Contestar';

  @override
  String get settleUpDisputeConfirm => 'Contestar este pagamento?';

  @override
  String get settleUpAwaitingConfirmation => 'Aguardando confirmação';

  @override
  String get settleUpConfirmed => 'Confirmado';

  @override
  String get settleUpDisputed => 'Contestado';

  @override
  String settleUpSuggestedAmount(String amount) {
    return 'Sugestão: $amount';
  }

  @override
  String get settleUpPaymentProofSection =>
      'Comprovante de pagamento (opcional)';

  @override
  String get settleUpAddProofLabel => 'Adicionar comprovante';

  @override
  String get settleUpProofUploadError =>
      'Não foi possível enviar o comprovante.';

  @override
  String get settleUpOffsetButton => 'Compensar dívida (encontro de contas)';

  @override
  String get settleUpOffsetConfirmTitle => 'Compensar esta dívida?';

  @override
  String get settleUpOffsetConfirmMessage =>
      'Isso usa seu crédito existente com esta pessoa para quitar a dívida do grupo sem movimentar dinheiro de verdade.';

  @override
  String get settleUpOffsetConfirmAction => 'Compensar';

  @override
  String get pendingSettlementYouPaidBeforeAmount => 'Você pagou ';

  @override
  String pendingSettlementYouPaidAfterAmount(String receiverName) {
    return ' para $receiverName';
  }

  @override
  String pendingSettlementReceivedBeforeAmount(String payerName) {
    return '$payerName te enviou ';
  }

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsEmpty => 'Nenhum amigo ainda. Convide alguém!';

  @override
  String get friendsInviteButton => 'Convidar amigo';

  @override
  String friendsOwes(String amount) {
    return 'Deve $amount';
  }

  @override
  String friendsOwed(String amount) {
    return 'Te deve $amount';
  }

  @override
  String get friendsEven => 'Quite';

  @override
  String get friendsSearchHint => 'Buscar amigos';

  @override
  String get friendInviteTitle => 'Convidar amigo';

  @override
  String get friendInviteBody =>
      'Geramos um link exclusivo. Envie por qualquer app para a pessoa entrar e aceitar depois de entrar na conta.';

  @override
  String get friendInviteButton => 'Gerar link de convite';

  @override
  String get friendInviteSuccess => 'Convite enviado!';

  @override
  String get friendInviteLinkCopied => 'Link de convite copiado!';

  @override
  String get friendAcceptInviteButton => 'Aceitar convite';

  @override
  String get friendAcceptSuccess => 'Convite aceito! Agora vocês são amigos.';

  @override
  String get inviteGetTheAppHint => 'Prefere o app? Baixe aqui.';

  @override
  String get inviteAppStoreButton => 'App Store';

  @override
  String get invitePlayStoreButton => 'Google Play';

  @override
  String get inviteOpenInAppHint =>
      'Já tem o Rachae instalado? Abra o app para aceitar este convite.';

  @override
  String get inviteOpenInAppButton => 'Abrir no app';

  @override
  String get friendDetailTitle => 'Detalhes';

  @override
  String get friendDetailNetBalance => 'Saldo entre vocês';

  @override
  String get friendDetailPendingSettlements => 'Pagamentos pendentes';

  @override
  String get friendDetailSharedExpenses => 'Despesas compartilhadas';

  @override
  String get friendDetailSharedGroups => 'Grupos em comum';

  @override
  String get friendDetailNoSharedExpenses => 'Nenhuma despesa compartilhada.';

  @override
  String get friendDetailSettleUpButton => 'Acertar contas';

  @override
  String get friendDetailAddToGroupButton => 'Adicionar ao grupo';

  @override
  String get friendDetailNoEligibleGroups =>
      'Nenhum grupo disponível para este amigo.';

  @override
  String friendDetailAddedToGroupSuccess(String friendName, String groupName) {
    return '$friendName foi adicionado(a) a $groupName!';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileDisplayNameLabel => 'Nome de exibição';

  @override
  String get profileEmailLabel => 'E-mail';

  @override
  String get profileEmailReadOnly => 'Gerenciado pelo Google';

  @override
  String get profileDefaultCurrencyLabel => 'Moeda padrão';

  @override
  String get profileSaveButton => 'Salvar alterações';

  @override
  String get profileSaveSuccess => 'Perfil atualizado!';

  @override
  String get profileAvatarChangeButton => 'Alterar foto';

  @override
  String get profileSignOutButton => 'Sair';

  @override
  String get profileSignOutConfirm => 'Tem certeza que deseja sair?';

  @override
  String get profileDeleteAccountButton => 'Excluir minha conta';

  @override
  String get profileDeleteAccountConfirmTitle => 'Excluir conta';

  @override
  String get profileDeleteAccountConfirm =>
      'Excluir sua conta é permanente e não pode ser desfeito. Continuar?';

  @override
  String get profileDeleteAccountSuccess => 'Conta excluída.';

  @override
  String get profileNotificationsSection => 'Notificações';

  @override
  String get profilePushExpenseCreated => 'Nova despesa adicionada';

  @override
  String get profilePushSettlementRecorded => 'Pagamento registrado';

  @override
  String get profilePushGroupInvitation => 'Convite de grupo';

  @override
  String get profileEmailExpenseCreated => 'E-mail: nova despesa';

  @override
  String get profileEmailSettlementRecorded => 'E-mail: pagamento registrado';

  @override
  String get profileAdFreeSection => 'Plano sem anúncios';

  @override
  String get profileAdFreeActive => 'Plano ativo — obrigado pelo suporte!';

  @override
  String profileAdFreeExpires(String date) {
    return 'Válido até $date';
  }

  @override
  String get profileAdFreeMonthlyLabel => 'Mensal';

  @override
  String get profileAdFreeYearlyLabel => 'Anual';

  @override
  String get profileAdFreeLifetimeLabel => 'Vitalício';

  @override
  String get profileAdFreePlanUnknown => 'Assinatura ativa';

  @override
  String profileAdFreeCurrentPlanLabel(String planName) {
    return 'Plano atual: $planName';
  }

  @override
  String get profilePlanChangeStripePortalFootnote =>
      'Use Gerenciar assinatura para mudar o plano. O Stripe aplica upgrades, downgrades e a cobrança conforme as regras da sua assinatura.';

  @override
  String get profileIosSubscriptionChangeFootnote =>
      'Para mudar o período de cobrança ou cancelar, use Gerenciar assinatura. A Apple faz upgrade/downgrade na mesma assinatura—evite comprar outro plano pelo paywall enquanto já estiver assinando.';

  @override
  String get profileSeeRachaeProPlansButton => 'Ver planos';

  @override
  String get profileSubscriptionManagedElsewhere =>
      'Alterações de assinatura não estão disponíveis no app. Entre em contato com o suporte se precisar de ajuda.';

  @override
  String profileAdFreePlanExpires(String date) {
    return 'Válido até $date';
  }

  @override
  String get profileUpgradeMonthlyButton => 'Assinar plano mensal';

  @override
  String get profileUpgradeYearlyButton => 'Assinar plano anual';

  @override
  String get profileUpgradeButton => 'Remover anúncios';

  @override
  String get profileManageSubscriptionButton => 'Gerenciar assinatura';

  @override
  String get profileExportButton => 'Exportar dados';

  @override
  String get exportTitle => 'Exportar dados';

  @override
  String get exportDateFromLabel => 'Data inicial';

  @override
  String get exportDateToLabel => 'Data final';

  @override
  String get exportGroupLabel => 'Grupo (opcional)';

  @override
  String get exportAllGroups => 'Todos os grupos';

  @override
  String get exportGroupAll => 'Todos os grupos';

  @override
  String get exportShareButton => 'Compartilhar PDF';

  @override
  String get exportGenerateButton => 'Gerar relatório';

  @override
  String get exportGenerating => 'Gerando relatório...';

  @override
  String get exportSuccess => 'Relatório gerado com sucesso!';

  @override
  String get exportError => 'Erro ao gerar relatório. Tente novamente.';

  @override
  String get sectionLoadError =>
      'Não foi possível carregar esta seção. Tente novamente.';

  @override
  String get profileLoadError =>
      'Não foi possível carregar seu perfil. Verifique a conexão e tente novamente.';

  @override
  String get profileAdsLoadError =>
      'Não foi possível carregar o status da assinatura.';

  @override
  String get profileCheckoutSessionError =>
      'Não foi possível iniciar o pagamento. Tente novamente.';

  @override
  String get profileCheckoutAlreadySubscribed =>
      'Você já tem uma assinatura ativa.';

  @override
  String get profileCheckoutCannotOpenUrl =>
      'Não foi possível abrir a página de pagamento. Tente novamente.';

  @override
  String get profileIapOfferingsUnavailable =>
      'As opções de assinatura não estão disponíveis no momento. Tente mais tarde.';

  @override
  String get profileRevenueCatMissingApiKey =>
      'Compras no app não estão configuradas nesta build. Execute com REVENUECAT_IOS_API_KEY (ex.: flutter run --dart-define-from-file=../.env na pasta frontend) e configure produtos na App Store Connect e no RevenueCat.';

  @override
  String get exportPdfDocumentTitle => 'Rachae - relatório de despesas';

  @override
  String get exportPdfEmptyReport => 'Sem dados para os filtros selecionados.';

  @override
  String exportPdfPeriod(String fromDate, String toDate) {
    return 'Período: $fromDate - $toDate';
  }

  @override
  String get exportPdfTotalSpent => 'Total gasto do grupo';

  @override
  String get exportPdfPerPersonTitle => 'Por pessoa (pago / devido / saldo)';

  @override
  String get exportPdfColumnPerson => 'Pessoa';

  @override
  String get exportPdfColumnPaid => 'Pago';

  @override
  String get exportPdfColumnOwed => 'Devido';

  @override
  String get exportPdfColumnNet => 'Saldo';

  @override
  String get exportPdfExpensesTitle => 'Linhas de despesa';

  @override
  String get exportPdfNoExpenses => 'Nenhuma despesa neste período.';

  @override
  String get exportPdfExpenseDescription => 'Descrição';

  @override
  String get exportPdfExpenseAmount => 'Valor';

  @override
  String get exportPdfExpenseDate => 'Data';

  @override
  String get exportPdfExpenseCategory => 'Categoria';

  @override
  String get exportPdfSettlementsTitle => 'Histórico de acertos';

  @override
  String get exportPdfNoSettlements => 'Nenhum acerto neste período.';

  @override
  String get exportPdfSettlementPayer => 'Pagador';

  @override
  String get exportPdfSettlementReceiver => 'Recebedor';

  @override
  String get exportPdfSettlementAmount => 'Valor';

  @override
  String get exportPdfSettlementDate => 'Data';

  @override
  String get adBannerFallback => '';

  @override
  String get adFreeUpgradeTitle => 'Remover anúncios';

  @override
  String get adFreeUpgradeDescription =>
      'Aproveite o Rachae sem interrupções. Um preço justo, sem rastreamento.';

  @override
  String get adFreeMonthlyPlan => 'Mensal';

  @override
  String get adFreeYearlyPlan => 'Anual';

  @override
  String get adFreeMonthlyPlanOption => 'Mensal (R\$ 4,99)';

  @override
  String get adFreeYearlyPlanOption => 'Anual (R\$ 29,99)';

  @override
  String get adFreeUpgradeButton => 'Assinar';

  @override
  String get adFreeCancelAnytime => 'Cancele quando quiser.';

  @override
  String get stageOneReady => 'Base da fase 1 pronta.';

  @override
  String get homeTitle => 'Início';

  @override
  String get signOut => 'Sair';

  @override
  String authenticatedMessage(String email) {
    return 'Logado como $email';
  }
}
