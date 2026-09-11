import 'package:flutter/foundation.dart';
class ApiConfig {

  //local
  //  static const String baseUrl = "http://10.0.2.2:8082/api";
  //  static const String wsBaseUrl = "ws://10.0.2.2:8082/api";
//aws
  static const String baseUrl = "http://34.207.233.126:8082/api";
static const String wsBaseUrl = "ws://34.207.233.126:8082/api";


  // static const String baseUrl = "http://192.168.0.102:8082/api";
  // static const String wsBaseUrl = "ws://192.168.0.102:8082/api";
 
 

  // static const String baseUrl = "http://127.0.0.1:8082/api";
  // static const String wsBaseUrl = "ws://127.0.0.1:8082/api";

  
  static const String wsGroupUpdates = "$wsBaseUrl/ws/groups";
  static const String wsTransactionsUpdates = "$wsBaseUrl/ws/transactions";

  static const String registerUser = "$baseUrl/users/register";
static const String registerBusiness = "$baseUrl/users/register/business";

  static const String getPendingWithdrawal = "$baseUrl/transactions/pending-withdraw/{address}";
  static const String withdrawTokens = "$baseUrl/transactions/withdraw";

  static const String buyTokens = "$baseUrl/transactions/buy";
  static const String buyFiat = "$baseUrl/transactions/buy-fiat";

  static const String sendTokens = "$baseUrl/transactions/send";
  static const String sendFiat = "$baseUrl/transactions/send-fiat";
  static const String sendOfChain = "$baseUrl/transactions/send-offchain";

  static const String stakeTokens = "$baseUrl/transactions/stake";
  static const String unstakeTokens = "$baseUrl/transactions/unstake";

  static const String getHistory = "$baseUrl/transactions/{address}";
  static const String getAnalytics = "$baseUrl/analytics/{address}";

  static const String getAlias = "$baseUrl/aliases/check/{alias}";
  static const String registerAlias = "$baseUrl/aliases/register";
  static const String getAliasWallet = "$baseUrl/users/{address}";
  static const String searchAlias = "$baseUrl/aliases/search/{alias}";
  static const String updateDailyLimit = "$baseUrl/users/{address}/limit";

  static const String getContacts = "$baseUrl/contacts/{address}";
  static const String addContact = "$baseUrl/contacts/add";
  static const String updateContact = "$baseUrl/contacts/{id}";
  static const String deleteContact = "$baseUrl/contacts/{id}";

  static const String sendOtp = "$baseUrl/auth/send-otp";
  static const String verifyOtp = "$baseUrl/auth/verify-otp";

  //static const String updateNotifications = "$baseUrl/users/{address}/notifications";

  static const String generate2FA = "$baseUrl/auth/2fa/generate";
  static const String enable2FA = "$baseUrl/auth/2fa/enable";
  static const String updateFcmToken = "$baseUrl/users/update-fcm";

  // --- GRUPOS ---
  static const String createGroup = "$baseUrl/groups/create";
  static const String acceptGroupInvite = "$baseUrl/groups/invite/accept";
  static const String rejectGroupInvite = "$baseUrl/groups/invite/reject";
  static const String getUserGroups = "$baseUrl/groups/user/{address}";
  static const String updateGroupName = "$baseUrl/groups/{id}/name";
  static const String deleteGroup = "$baseUrl/groups/{id}";
  static const String removeGroupMember = "$baseUrl/groups/{id}/members/{address}";
  static const String addGroupMember = "$baseUrl/groups/{id}/members";
  static const String getGroupTransactionsHistory = "$baseUrl/groups/{groupId}/transactions";
  static const String proposeGroupThreshold = "$baseUrl/payments/groups/{groupId}/threshold";
  
  // --- CHAT GRUPAL ---
  static const String getGroupChatHistory = "$baseUrl/groups/{groupId}/chat";
  static const String sendGroupMessage = "$baseUrl/groups/{groupId}/chat";
  

  static const String createGroupPayment = "$baseUrl/payments/groups/request";
  static const String getGroupPayments = "$baseUrl/payments/groups/{groupId}";
  static const String confirmGroupPayment = "$baseUrl/payments/groups/pay";
  static const String approveMultisigTransaction = "$baseUrl/payments/groups/{requestId}/approve";
  static const String getGroupBalance = "$baseUrl/transactions/balance/{walletAddress}";
  static const String stakeGroupTokens = "$baseUrl/payments/groups/{groupId}/{actionType}";

  // --- LLAMADAS Y SEÑALIZACIÓN ---
  static const String wakeUpCall = "$baseUrl/calls/wake-up";
  // Variables faltantes para Grupos:
  static const String updateGroup = "$baseUrl/groups/{id}";


  static const String getScheduledPayments = "$baseUrl/payments/scheduled/user/{address}";
static const String cancelScheduledPayment = "$baseUrl/payments/scheduled/{id}";

// --- RUTAS DE DEUDAS (SOCIALIZED DEBT) ---
  static const String createDebt = "$baseUrl/debts/request";
  static const String respondDebt = "$baseUrl/debts/{debtId}/respond";
  static const String payDebt = "$baseUrl/debts/{debtId}/pay";
  static const String getUserDebts = "$baseUrl/debts/user/{walletAddress}";
  
  static const String shareDebtGroup = "$baseUrl/debts/share";
  static const String voteSharedDebt = "$baseUrl/debts/shared/{sharedId}/vote";
  static const String contributeSharedDebt = "$baseUrl/debts/shared/{sharedId}/contribute";
  static const String getGroupSharedDebts = "$baseUrl/debts/group/{groupId}";

  // --- DOCUMENT NOTARY ---
 static const String createDocument = "$baseUrl/documents/create";
  static const String getPendingDocuments = "$baseUrl/documents/pending/{address}";
  static const String signDocument = "$baseUrl/documents/{hash}/sign";
  static const String getDocumentInfo = "$baseUrl/documents/info/{hash}";
  static const String getDocumentHistory = "$baseUrl/documents/history/{address}";
  static const String getDocumentHistoryPaged = "$baseUrl/documents/history/paged/{address}";
  static String get wsDocumentUpdates => baseUrl.replaceFirst("http", "ws") + "/ws/documents/{address}";

  //Seguridad
  static const String toggleFreeze = "$baseUrl/users/{address}/freeze";

  //redireccion
  static const String getPayeeInfo = "$baseUrl/users/payee-info/{identifier}";

  //Seguridad de dispositivos
  static const String getDevices = "$baseUrl/users/{address}/devices";
  static const String revokeDevices = "$baseUrl/users/{address}/devices/revoke";

  static const String getTransactionByHash = "$baseUrl/transactions/hash/{hash}";

  
  static const String createVault = "$baseUrl/vaults/create";
  static const String withdrawVault = "$baseUrl/vaults/{vaultId}/withdraw";
  static const String getUserVaults = "$baseUrl/vaults/{address}";
  static String get wsVaultUpdates => baseUrl.replaceFirst("http", "ws") + "/ws/vaults/{address}";

  static const String depositVault = "$baseUrl/vaults/{vaultId}/deposit";


  static const String getMerchantSubscriptions = "$baseUrl/payments/scheduled/merchant/{address}";
  static const String sendMerchantReminder = "$baseUrl/payments/scheduled/remind";

  // --- BILLETERAS DESECHABLES (BURNER WALLETS) ---
  static const String getBurners = "$baseUrl/burners/{address}";
  static const String createBurner = "$baseUrl/burners/create";
  static const String burnWallet = "$baseUrl/burners/burn";
  static const String sendFromBurner = "$baseUrl/burners/send";
  static const String getBurnerTransactionsHistory = "$baseUrl/burners/{address}/transactions";

  // --- MODO PÁNICO (BÓVEDA SEÑUELO) ---
  static const String setupDecoy = "$baseUrl/panic/setup";
  static const String verifyPanic = "$baseUrl/panic/verify";
  static const String deleteDecoy = "$baseUrl/panic/{address}";
  static const String getDecoy = "$baseUrl/panic/{address}";

  // --- CROWDFUNDING (DeFi GoFundMe) ---
 static const String getCampaigns = "$baseUrl/campaigns"; 
  static const String getCampaignById = "$baseUrl/campaigns/{id}";
  static const String createCampaign = "$baseUrl/campaigns";
  static const String pledgeCampaign = "$baseUrl/campaigns/{id}/pledge";
  static const String toggleCrowdfunding = "$baseUrl/users/{address}/crowdfunding";
  static const String claimCampaign = "$baseUrl/campaigns/{id}/claim";
  static const String cancelCampaign = "$baseUrl/campaigns/{id}/cancel";
  static const String wsCampaigns = "$wsBaseUrl/campaigns/";
 // static const String verifyPanic = "$baseUrl/panic/verify";

 static const String publicPlansConfig = "$baseUrl/plans/config";
 static const String upgradeCryptoPlan = "$baseUrl/plans/upgrade-crypto";
 static const String cancelAutoRenew = "$baseUrl/plans/cancel-auto-renew";
 static const String adminPlans = "$baseUrl/admin";
  static const String getPendingBusinesses = "$baseUrl/admin/businesses/pending";
  static const String reviewBusiness = "$baseUrl/admin/businesses/{address}/review";
  static const String adminSubscriptionAnalytics = "$baseUrl/admin/subscriptions/analytics";
  static String adminUpdateUserTier(String wallet) => "$baseUrl/admin/users/$wallet/tier";
  static String adminUsersByTier(String tier) => "$baseUrl/admin/subscriptions/users/$tier";
  static const String adminWhaleTransactions = "$baseUrl/admin/compliance/whales";
  static const String adminFailedTransactions = "$baseUrl/admin/compliance/failures";
  static const String adminStuckCampaigns = "$baseUrl/admin/support/stuck-campaigns";
  static String adminForceRefundCampaign(String id) => "$baseUrl/admin/support/campaigns/$id/force-refund";

  static const String chatWebSocket = "ws://10.0.2.2:8082/api/ws/chat";
  //static const String chatWebSocket = "ws://192.168.0.102:8082/api/ws/chat";
  static const String chatHistory = "$baseUrl/chat/history/{peerWallet}";
  static const String getChatInbox = "$baseUrl/chat/inbox";
  static const String deleteChatHistory = "$baseUrl/chat/history/{peerWallet}";
  static const String uploadChatMedia = "$baseUrl/chat/media/upload";

  static const String getNotifications = "$baseUrl/notifications";
  static const String markNotificationRead = "$baseUrl/notifications/{id}/read";
  static const String clearNotifications = "$baseUrl/notifications/clear";

  // --- BUSINESS / EMPRESAS ---
  static const String inviteTeamMember = "$baseUrl/business/invite";
  static const String getPendingInvites = "$baseUrl/business/invites/{address}";
  static const String respondBusinessInvite = "$baseUrl/business/invites/respond";
  static const String getTeamMembers = "$baseUrl/business/{address}/team";
  static const String removeTeamMember = "$baseUrl/business/{address}/team/{identifier}";
  static const String getTeamWithDetails = "$baseUrl/business/{address}/team/details";
  static const String getMyEmployers = "$baseUrl/business/employers/{address}";
  static const String getTeamDashboard = "$baseUrl/business/{address}/team/dashboard";
  // --- DEPARTAMENTOS ---
  static const String getDepartments = "$baseUrl/business/departments/{address}";
  static const String createDepartment = "$baseUrl/business/departments";
  static const String addDepartmentMember = "$baseUrl/business/departments/{departmentId}/members";
  static const String removeDepartmentMember = "$baseUrl/business/departments/{departmentId}/members/{wallet}";
  static const String deleteDepartment = "$baseUrl/business/departments/{departmentId}";

  // --- BUSINESS TASKS ---
  static const String createBusinessTask = "$baseUrl/business/tasks";
  static const String getBusinessTasksEmployer = "$baseUrl/business/tasks/employer/{address}";
  static const String getBusinessTasksEmployee = "$baseUrl/business/tasks/employee/{address}";
  static const String updateBusinessTaskStatus = "$baseUrl/business/tasks/{taskId}/status";
  static const String editBusinessTask = "$baseUrl/business/tasks/{taskId}";
  static const String deleteBusinessTask = "$baseUrl/business/tasks/{taskId}";
  static const String getUserWorkload = "$baseUrl/business/tasks/workload/{wallet}";
  static const String reassignBusinessTask = "$baseUrl/business/tasks/{taskId}/reassign";

  // --- FAMILIA ---
  static const String inviteFamily = "$baseUrl/family/invite";
  static const String getFamilyInvites = "$baseUrl/family/invites/{address}";
  static const String respondFamilyInvite = "$baseUrl/family/invites/respond";
  static const String getFamilyMembers = "$baseUrl/family/members/{address}";

  // --- PAYPAL FIAT P2P ---
  static const String paypalConfig = "$baseUrl/paypal/config";
  static const String paypalCheckPayee = "$baseUrl/paypal/check-payee/{identifier}";
  static const String paypalCreateOrder = "$baseUrl/paypal/create-order";
  static const String paypalCaptureOrder = "$baseUrl/paypal/capture-order/{orderId}";

  // --- CONFIGURACIONES MODULARES ---
  static const String getUserConfig = "$baseUrl/settings/{address}";
  static const String updateNotifications = "$baseUrl/settings/{address}/notifications";
  static const String updateDailyLimitSetting = "$baseUrl/settings/{address}/limit";
  static const String updateCrowdfundingSetting = "$baseUrl/settings/{address}/crowdfunding";

  // --- AI MEMORY (RAG) ---
  static const String getAiMemory = "$baseUrl/ai/memory/{address}";
  static const String toggleAiMemory = "$baseUrl/ai/memory/{address}/toggle/{id}";
  static const String aiChat = "$baseUrl/ai/chat-memory";

  static const String testAiPush = "$baseUrl/notifications/test-ai-push";

  // --- BUSINESS GROUPS (Grupos Corporativos) ---
  static const String createBusinessGroup = "$baseUrl/business-groups/create-area";
  static const String getBusinessGroupsEmployer = "$baseUrl/business-groups/business/{address}";
  static const String getBusinessGroupsEmployee = "$baseUrl/business-groups/employee/{address}";
  static const String getBusinessGroupMembers = "$baseUrl/business-groups/{groupId}/members";
  static const String removeBusinessGroupMember = "$baseUrl/business-groups/{groupId}/members/{wallet}";
  static const String getBusinessGroupProductivity = "$baseUrl/business-groups/{groupId}/productivity";
  static const String addBusinessGroupResource = "$baseUrl/business-groups/{groupId}/resources";
  static const String addBusinessGroupGoal = "$baseUrl/business-groups/{groupId}/goals";
  static const String updateBusinessGroupAnnouncement = "$baseUrl/business-groups/{groupId}/announcement";
  static const String getBusinessGroupById = "$baseUrl/business-groups/{groupId}";
  static const String auditBusinessGroupMember = "$baseUrl/business-groups/{groupId}/audit/{address}";
  //static const String updateBusinessGroupResource = "$baseUrl/business-groups/{groupId}/resources/{resourceId}";
  static const String deleteBusinessGroupResource = "$baseUrl/business-groups/{groupId}/resources/{resourceId}";
  //static const String updateBusinessGroupGoal = "$baseUrl/business-groups/{groupId}/goals/{goalId}";
  static const String deleteBusinessGroupGoal = "$baseUrl/business-groups/{groupId}/goals/{goalId}";
  static const String addBusinessGroupGoalProgress = "$baseUrl/business-groups/{groupId}/goals/{goalId}/progress";
  static const String updateBusinessGroupResource = "$baseUrl/business-groups/{groupId}/resources/{resourceId}";
  static const String updateBusinessGroupGoal = "$baseUrl/business-groups/{groupId}/goals/{goalId}";

  static const String getHistoryPaged = "$baseUrl/history/paged/{address}";

  static String aiStream(String address) => "$baseUrl/ai/memory/$address/stream";
  static String aiExtract(String address) => "$baseUrl/ai/memory/$address/extract";

}


final ValueNotifier<bool> showCrowdfundingGlobal = ValueNotifier(true);
final ValueNotifier<bool> isBusinessModeGlobal = ValueNotifier(false);
