{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Provides actions for Channel API interactions
module Discord.Internal.Rest.Guild
  ( GuildRequest(..)
  , CreateGuildChannelOpts(..)
  , ModifyGuildOpts(..)
  , AddGuildMemberOpts(..)
  , ModifyGuildMemberOpts(..)
  , GuildMembersTiming(..)
  , CreateGuildBanOpts(..)
  , ModifyGuildRoleOpts(..)
  , CreateGuildIntegrationOpts(..)
  , ModifyGuildIntegrationOpts(..)
  , ListActiveThreads (..)
  , GetAuditLogOpts (..)
  , toAuditLogEvent
  ) where


import Data.Aeson
import Network.HTTP.Req ((/:), (/~))
import qualified Network.HTTP.Req as R
import qualified Data.Text as T

import Discord.Internal.Rest.Prelude
import Discord.Internal.Types
import Data.Default (Default(..))

import Discord.Internal.Types.ApplicationCommands (ApplicationCommand)
import Discord.Internal.Types.ScheduledEvents (ScheduledEvent)

instance Request (GuildRequest a) where
  majorRoute = guildMajorRoute
  jsonRequest = guildJsonRequest

-- | Data constructor for requests. See <https://discord.com/developers/docs/resources/ API>
data GuildRequest a where
  -- -- Creating a guild with the API is annoying. Do it manually.
  -- -- https://discord.com/developers/docs/resources/guild#create-guild

  -- | Returns the new 'Guild' object for the given id
  GetGuild                 :: GuildId -> GuildRequest Guild
  -- | Modify a guild's settings. Returns the updated 'Guild' object on success. Fires a
  --   Guild Update 'Event'.
  ModifyGuild              :: GuildId -> ModifyGuildOpts -> GuildRequest Guild
  -- | Delete a guild permanently. User must be owner. Fires a Guild Delete 'Event'.
  DeleteGuild              :: GuildId -> GuildRequest ()
  -- | Returns a list of guild 'Channel' objects
  GetGuildChannels         :: GuildId -> GuildRequest [Channel]
  -- | Create a new 'Channel' object for the guild. Requires 'MANAGE_CHANNELS'
  --   permission. Returns the new 'Channel' object on success. Fires a Channel Create
  --   'Event'
  CreateGuildChannel       :: GuildId -> T.Text -> [Overwrite] -> CreateGuildChannelOpts -> GuildRequest Channel
  -- | Modify the positions of a set of channel objects for the guild. Requires
  --   'MANAGE_CHANNELS' permission. Returns a list of all of the guild's 'Channel'
  --   objects on success. Fires multiple Channel Update 'Event's.
  ModifyGuildChannelPositions      :: GuildId -> [(ChannelId,Int)] -> GuildRequest [Channel]
  -- | Returns a list of active threads in a guild
  ListActiveGuildThreads   :: GuildId -> GuildRequest ListActiveThreads
  -- | Returns a guild 'Member' object for the specified user
  GetGuildMember           :: GuildId -> UserId -> GuildRequest GuildMember
  -- | Returns a list of guild 'Member' objects that are members of the guild.
  ListGuildMembers         :: GuildId -> GuildMembersTiming -> GuildRequest [GuildMember]
  -- | Adds a user to the guild, provided you have a valid oauth2 access token
  --   for the user with the guilds.join scope. Returns the guild 'Member' as the body.
  --   Fires a Guild Member Add 'Event'. Requires the bot to have the
  --   CREATE_INSTANT_INVITE permission.
  AddGuildMember           :: GuildId -> UserId -> AddGuildMemberOpts -> GuildRequest ()
  -- | Modify attributes of a guild 'Member'. Fires a Guild Member Update 'Event'.
  ModifyGuildMember        :: GuildId -> UserId -> ModifyGuildMemberOpts -> GuildRequest GuildMember
  -- | Modify the nickname of the current user
  ModifyCurrentUserNick    :: GuildId -> T.Text -> GuildRequest ()
  -- | Add a member to a guild role. Requires 'MANAGE_ROLES' permission.
  AddGuildMemberRole       :: GuildId -> UserId -> RoleId -> GuildRequest ()
  -- | Remove a member from a guild role. Requires 'MANAGE_ROLES' permission.
  RemoveGuildMemberRole    :: GuildId -> UserId -> RoleId -> GuildRequest ()
  -- | Remove a member from a guild. Requires 'KICK_MEMBER' permission. Fires a
  --   Guild Member Remove 'Event'.
  RemoveGuildMember        :: GuildId -> UserId -> GuildRequest ()
  -- | Returns a list of 'Ban' objects for users that are banned from this guild. Requires the
  --   'BAN_MEMBERS' permission
  GetGuildBans             :: GuildId -> GuildRequest [GuildBan]
  -- | Returns a 'Ban' object for the user banned from this guild. Requires the
  --   'BAN_MEMBERS' permission
  GetGuildBan              :: GuildId -> UserId -> GuildRequest GuildBan
  -- | Create a guild ban, and optionally Delete previous messages sent by the banned
  --   user. Requires the 'BAN_MEMBERS' permission. Fires a Guild Ban Add 'Event'.
  CreateGuildBan           :: GuildId -> UserId -> CreateGuildBanOpts -> GuildRequest ()
  -- | Remove the ban for a user. Requires the 'BAN_MEMBERS' permissions.
  --   Fires a Guild Ban Remove 'Event'.
  RemoveGuildBan           :: GuildId -> UserId -> GuildRequest ()
  -- | Returns a list of 'Role' objects for the guild. Requires the 'MANAGE_ROLES'
  --   permission
  GetGuildRoles            :: GuildId -> GuildRequest [Role]
  -- | Create a new 'Role' for the guild. Requires the 'MANAGE_ROLES' permission.
  --   Returns the new role object on success. Fires a Guild Role Create 'Event'.
  CreateGuildRole          :: GuildId -> ModifyGuildRoleOpts -> GuildRequest Role
  -- | Modify the positions of a set of role objects for the guild. Requires the
  --   'MANAGE_ROLES' permission. Returns a list of all of the guild's 'Role' objects
  --   on success. Fires multiple Guild Role Update 'Event's.
  ModifyGuildRolePositions :: GuildId -> [(RoleId, Integer)] -> GuildRequest [Role]
  -- | Modify a guild role. Requires the 'MANAGE_ROLES' permission. Returns the
  --   updated 'Role' on success. Fires a Guild Role Update 'Event's.
  ModifyGuildRole          :: GuildId -> RoleId -> ModifyGuildRoleOpts -> GuildRequest Role
  -- | Delete a guild role. Requires the 'MANAGE_ROLES' permission. Fires a Guild Role
  --   Delete 'Event'.
  DeleteGuildRole          :: GuildId -> RoleId -> GuildRequest ()
  -- | Returns an object with one 'pruned' key indicating the number of members
  --   that would be removed in a prune operation. Requires the 'KICK_MEMBERS'
  --   permission.
  GetGuildPruneCount       :: GuildId -> Integer -> GuildRequest Object
  -- | Returns an AuditLog object, includes options about time, action type,
  --   user that took the action and amount of entries to fetch.
  --   Requires 'VIEW_AUDIT_LOG' permission
  GetGuildAuditLog         :: GuildId -> GetAuditLogOpts -> GuildRequest AuditLog
  -- | Begin a prune operation. Requires the 'KICK_MEMBERS' permission. Returns an
  --   object with one 'pruned' key indicating the number of members that were removed
  --   in the prune operation. Fires multiple Guild Member Remove 'Events'.
  BeginGuildPrune          :: GuildId -> Integer -> GuildRequest Object
  -- | Returns a list of 'VoiceRegion' objects for the guild. Unlike the similar /voice
  --   route, this returns VIP servers when the guild is VIP-enabled.
  GetGuildVoiceRegions     :: GuildId -> GuildRequest [VoiceRegion]
  -- | Returns a list of 'Invite' objects for the guild. Requires the 'MANAGE_GUILD'
  --   permission.
  GetGuildInvites          :: GuildId -> GuildRequest [Invite]
  -- | Return a list of 'Integration' objects for the guild. Requires the 'MANAGE_GUILD'
  --   permission.
  GetGuildIntegrations     :: GuildId -> GuildRequest [Integration]
  -- | Attach an 'Integration' object from the current user to the guild. Requires the
  --   'MANAGE_GUILD' permission. Fires a Guild Integrations Update 'Event'.
  CreateGuildIntegration   :: GuildId -> IntegrationId -> CreateGuildIntegrationOpts -> GuildRequest ()
  -- | Modify the behavior and settings of a 'Integration' object for the guild.
  --   Requires the 'MANAGE_GUILD' permission. Fires a Guild Integrations Update 'Event'.
  ModifyGuildIntegration   :: GuildId -> IntegrationId -> ModifyGuildIntegrationOpts
                                      -> GuildRequest ()
  -- | Delete the attached 'Integration' object for the guild. Requires the
  --   'MANAGE_GUILD' permission. Fires a Guild Integrations Update 'Event'.
  DeleteGuildIntegration   :: GuildId -> IntegrationId -> GuildRequest ()
  -- | Sync an 'Integration'. Requires the 'MANAGE_GUILD' permission.
  SyncGuildIntegration     :: GuildId -> IntegrationId -> GuildRequest ()
  -- | Returns the 'GuildWidget' object. Requires the 'MANAGE_GUILD' permission.
  GetGuildWidget           :: GuildId -> GuildRequest GuildWidget
  -- | Modify a 'GuildWidget' object for the guild. All attributes may be passed in with
  --   JSON and modified. Requires the 'MANAGE_GUILD' permission. Returns the updated
  --   'GuildWidget' object.
  ModifyGuildWidget        :: GuildId -> GuildWidget -> GuildRequest GuildWidget
  -- | Vanity URL
  GetGuildVanityURL        :: GuildId -> GuildRequest T.Text

-- | Options for `ModifyGuildIntegration`
data ModifyGuildIntegrationOpts = ModifyGuildIntegrationOpts
  { modifyGuildIntegrationOptsExpireBehavior :: Integer
  , modifyGuildIntegrationOptsExpireGraceSeconds :: Integer
  , modifyGuildIntegrationOptsEmoticonsEnabled :: Bool
  } deriving (Show, Read, Eq, Ord)

instance ToJSON ModifyGuildIntegrationOpts where
  toJSON ModifyGuildIntegrationOpts{..} = objectFromMaybes
         [ "expire_grace_period" .== modifyGuildIntegrationOptsExpireGraceSeconds
         , "expire_behavior" .== modifyGuildIntegrationOptsExpireBehavior
         , "enable_emoticons" .== modifyGuildIntegrationOptsEmoticonsEnabled ]

-- | Options for `CreateGuildIntegration`
newtype CreateGuildIntegrationOpts = CreateGuildIntegrationOpts
  { createGuildIntegrationOptsType :: T.Text
  } deriving (Show, Read, Eq, Ord)

instance ToJSON CreateGuildIntegrationOpts where
  toJSON CreateGuildIntegrationOpts{..} = objectFromMaybes
                       ["type" .== createGuildIntegrationOptsType]

-- | Options for `CreateGuildBan`
data CreateGuildBanOpts = CreateGuildBanOpts
  { createGuildBanOptsDeleteLastNMessages :: Maybe Int
  , createGuildBanOptsReason              :: Maybe T.Text
  } deriving (Show, Read, Eq, Ord)

instance ToJSON CreateGuildBanOpts where
  toJSON CreateGuildBanOpts{..} = objectFromMaybes
                       [ "delete_message_days"
                           .=? createGuildBanOptsDeleteLastNMessages
                       , "reason" .=? createGuildBanOptsReason]

-- | Options for `ModifyGuildRole`
data ModifyGuildRoleOpts = ModifyGuildRoleOpts
  { modifyGuildRoleOptsName            :: Maybe T.Text
  , modifyGuildRoleOptsPermissions     :: Maybe RolePermissions
  , modifyGuildRoleOptsColor           :: Maybe DiscordColor
  , modifyGuildRoleOptsSeparateSidebar :: Maybe Bool
  , modifyGuildRoleOptsMentionable     :: Maybe Bool
  , modifyGuildRoleOptsIcon            :: Maybe T.Text
  } deriving (Show, Read, Eq, Ord)

instance ToJSON ModifyGuildRoleOpts where
  toJSON ModifyGuildRoleOpts{..} = objectFromMaybes
                       ["name" .=? modifyGuildRoleOptsName,
                        "permissions" .=? modifyGuildRoleOptsPermissions,
                        "color" .=? modifyGuildRoleOptsColor,
                        "hoist" .=? modifyGuildRoleOptsSeparateSidebar,
                        "mentionable" .=? modifyGuildRoleOptsMentionable,
                        "icon" .=? modifyGuildRoleOptsIcon]

-- | Options for `AddGuildMember`
data AddGuildMemberOpts = AddGuildMemberOpts
  { addGuildMemberOptsAccessToken :: T.Text
  , addGuildMemberOptsNickname    :: Maybe T.Text
  , addGuildMemberOptsRoles       :: Maybe [RoleId]
  , addGuildMemberOptsIsMuted     :: Maybe Bool
  , addGuildMemberOptsIsDeafened  :: Maybe Bool
  } deriving (Show, Read, Eq, Ord)

instance ToJSON AddGuildMemberOpts where
  toJSON AddGuildMemberOpts{..} = objectFromMaybes
                                  ["access_token" .== addGuildMemberOptsAccessToken,
                                   "nick" .=? addGuildMemberOptsNickname,
                                   "roles" .=? addGuildMemberOptsRoles,
                                   "mute" .=? addGuildMemberOptsIsMuted,
                                   "deaf" .=? addGuildMemberOptsIsDeafened]

-- | Options for `ModifyGuildMember`
data ModifyGuildMemberOpts = ModifyGuildMemberOpts
  { modifyGuildMemberOptsNickname      :: Maybe T.Text
  , modifyGuildMemberOptsRoles         :: Maybe [RoleId]
  , modifyGuildMemberOptsIsMuted       :: Maybe Bool
  , modifyGuildMemberOptsIsDeafened    :: Maybe Bool
  , modifyGuildMemberOptsMoveToChannel :: Maybe ChannelId
  , modifyGuildMemberOptsTimeoutUntil  :: Maybe (Maybe UTCTime) -- ^ If `Just Nothing`, the timeout will be removed.
  } deriving (Show, Read, Eq, Ord)

instance Default ModifyGuildMemberOpts where
  def = ModifyGuildMemberOpts Nothing Nothing Nothing Nothing Nothing Nothing

instance ToJSON ModifyGuildMemberOpts where
  toJSON ModifyGuildMemberOpts{..} = objectFromMaybes
                                  ["nick" .=? modifyGuildMemberOptsNickname,
                                   "roles" .=? modifyGuildMemberOptsRoles,
                                   "mute" .=? modifyGuildMemberOptsIsMuted,
                                   "deaf" .=? modifyGuildMemberOptsIsDeafened,
                                   "channel_id" .=? modifyGuildMemberOptsMoveToChannel,
                                   "communication_disabled_until" .=? modifyGuildMemberOptsTimeoutUntil]

-- | Options for `CreateGuildChannel`
data CreateGuildChannelOpts
  -- | Create a text channel
  = CreateGuildChannelOptsText {
    createGuildChannelOptsTopic :: Maybe T.Text
  , createGuildChannelOptsUserMessageRateDelay :: Maybe Integer
  , createGuildChannelOptsIsNSFW :: Maybe Bool
  , createGuildChannelOptsCategoryId :: Maybe ChannelId }
  -- | Create a voice channel
  | CreateGuildChannelOptsVoice {
    createGuildChannelOptsBitrate :: Maybe Integer
  , createGuildChannelOptsMaxUsers :: Maybe Integer
  , createGuildChannelOptsCategoryId :: Maybe ChannelId }
  -- | Create a category
  | CreateGuildChannelOptsCategory
  deriving (Show, Read, Eq, Ord)

-- | Converts a channel name, a list of permissions and other channel options into a JSON Value 
createChannelOptsToJSON :: T.Text -> [Overwrite] -> CreateGuildChannelOpts -> Value
createChannelOptsToJSON name perms opts = objectFromMaybes optsJSON
  where
  optsJSON = case opts of
    CreateGuildChannelOptsText{..} ->
                          ["name" .== String name
                          ,"type" .== Number 0
                          ,"permission_overwrites" .== perms
                          ,"topic" .=? createGuildChannelOptsTopic
                          ,"rate_limit_per_user" .=? createGuildChannelOptsUserMessageRateDelay
                          ,"nsfw" .=? createGuildChannelOptsIsNSFW
                          ,"parent_id" .=? createGuildChannelOptsCategoryId]
    CreateGuildChannelOptsVoice{..} ->
                          ["name" .== String name
                          ,"type" .== Number 2
                          ,"permission_overwrites" .== perms
                          ,"bitrate" .=? createGuildChannelOptsBitrate
                          ,"user_limit" .=? createGuildChannelOptsMaxUsers
                          ,"parent_id" .=? createGuildChannelOptsCategoryId]
    CreateGuildChannelOptsCategory ->
                          ["name" .== String name
                          ,"type" .== Number 4
                          ,"permission_overwrites" .== perms]


-- | Options for `ModifyGuild`
--
-- See <https://discord.com/developers/docs/resources/guild#modify-guild>
data ModifyGuildOpts = ModifyGuildOpts
  { modifyGuildOptsName         :: Maybe T.Text
  , modifyGuildOptsAFKChannelId :: Maybe ChannelId
  , modifyGuildOptsIcon         :: Maybe T.Text
  , modifyGuildOptsOwnerId      :: Maybe UserId
   -- Region
   -- VerificationLevel
   -- DefaultMessageNotification
   -- ExplicitContentFilter
  } deriving (Show, Read, Eq, Ord)

instance ToJSON ModifyGuildOpts where
  toJSON ModifyGuildOpts{..} = objectFromMaybes
                                  ["name" .=? modifyGuildOptsName,
                                   "afk_channel_id" .=? modifyGuildOptsAFKChannelId,
                                   "icon" .=? modifyGuildOptsIcon,
                                   "owner_id" .=? modifyGuildOptsOwnerId]

data GuildMembersTiming = GuildMembersTiming
                          { guildMembersTimingLimit :: Maybe Int
                          , guildMembersTimingAfter :: Maybe UserId
                          } deriving (Show, Read, Eq, Ord)

-- | result for `ListGuildActiveThreads`
data ListActiveThreads = ListActiveThreads
  { listActiveThreadsThreads :: [Channel]
  , listActiveThreadsMembers :: [ThreadMember]
  } deriving (Show, Read, Eq, Ord)

instance ToJSON ListActiveThreads where
  toJSON ListActiveThreads{..} = object
    [ ("threads", toJSON listActiveThreadsThreads)
    , ("members", toJSON listActiveThreadsMembers)
    ]

instance FromJSON ListActiveThreads where
  parseJSON = withObject "ListActiveThreads" $ \o ->
    ListActiveThreads <$> o .: "threads"
                      <*> o .: "members"

-- | Audit log object, along with the entries it also contains referenced users, integrations [...] and so on
data AuditLog = AuditLog
  { auditLogEntries             :: [AuditLogEntry]
  , auditLogUsers               :: [User]
  , auditLogIntegrations        :: [Integration]
  , auditLogWebhooks            :: [Webhook]
  , auditlogScheduledEvents     :: [ScheduledEvent]
  , auditLogThreads             :: [Channel]
  , auditLogApplicationCommands :: [ApplicationCommand]
  , auditLogAutoModerationRules :: [AutoModerationRule]
  } deriving ( Show, Read )


instance FromJSON AuditLog where
  parseJSON = withObject "AuditLog" $ \o ->
    AuditLog <$> o .: "audit_log_entries"
             <*> o .: "users"
             <*> o .: "integrations"
             <*> o .: "webhooks"
             <*> o .: "guild_scheduled_events"
             <*> o .: "threads"
             <*> o .: "application_commands"
             <*> o .: "auto_moderation_rules"

-- | An audit log entry object, so to speak the actual event that took place
data AuditLogEntry = AuditLogEntry
  { auditLogEntryId         :: AuditLogEntryId
  , auditLogEntryActionType :: AuditLogEvent
  , auditLogEntryUserId     :: Maybe UserId
  , auditLogEntryTargetId   :: Maybe Snowflake
  , auditLogEntryChanges    :: Maybe [AuditLogChange]
  , auditLogEntryOptions    :: Maybe AuditLogEntryOptions
  , auditLogEntryReasons    :: Maybe String
  } deriving ( Show, Read)

instance FromJSON AuditLogEntry where
  parseJSON = withObject "AuditLogEntry" $ \o ->
    AuditLogEntry <$> o .:  "id"
                  <*> o .:  "action_type"
                  <*> o .:? "user_id"
                  <*> o .:? "target_id"
                  <*> o .:? "changes"
                  <*> o .:? "options"
                  <*> o .:? "reasons"

newtype AuditLogEvent = MkAuditLogEvent Int
  deriving ( Show, Read )

instance FromJSON AuditLogEvent where
  parseJSON = fmap MkAuditLogEvent . parseJSON

-- | A change object, new value and old value fields are of Aesons `Value` type,
--   because it can be pretty much any value from discord api
data AuditLogChange = AuditLogChange
  { auditLogChangeKey      :: String
  , auditLogChangeNewValue :: Maybe Value
  , auditLogChangeOldValue :: Maybe Value
  } deriving ( Show, Read )

instance FromJSON AuditLogChange where
  parseJSON = withObject "AuditLogChange" $ \o ->
    AuditLogChange <$> o .:  "key"
                   <*> o .:? "new_value"
                   <*> o .:? "old_value"

-- | Optional data for the Audit Log Entry object
data AuditLogEntryOptions = AuditLogEntryOptions
  { auditLogEntryOptionApplicationId                  :: Maybe ApplicationId
  , auditLogEntryOptionAutoModerationRuleName         :: Maybe String
  , auditLogEntryOptionAutoModerationRuleTriggerType  :: Maybe String
  , auditLogEntryOptionChannelId                      :: Maybe ChannelId
  , auditLogEntryOptionCount                          :: Maybe String
  , auditLogEntryOptionDeleteMemberDays               :: Maybe String
  , auditLogEntryOptionId                             :: Maybe Snowflake
  , auditLogEntryOptionMembersRemoved                 :: Maybe String
  , auditLogEntryOptionMessageId                      :: Maybe MessageId
  , auditLogEntryOptionRoleName                       :: Maybe String
  , auditLogEntryOptionType                           :: Maybe String
  , auditLogEntryOptionIntegrationType                :: Maybe String
  } deriving ( Show, Read )

instance FromJSON AuditLogEntryOptions where
  parseJSON = withObject "AuditLogEntryOption" $ \o ->
    AuditLogEntryOptions <$> o .:? "application_id"
                         <*> o .:? "auto_moderation_rule_name"
                         <*> o .:? "auto_moderation_rule_trigger_type"
                         <*> o .:? "channel_id"
                         <*> o .:? "count"
                         <*> o .:? "delete_member_days"
                         <*> o .:? "id"
                         <*> o .:? "members_removed"
                         <*> o .:? "message_id"
                         <*> o .:? "role_name"
                         <*> o .:? "type"
                         <*> o .:? "integration_type"

-- | Options for `GetAuditLog` request
data GetAuditLogOpts = GetAuditLogOpts
  { getAuditLogUserId     :: Maybe UserId
  , getAuditLogActionType :: Maybe AuditLogEvent
  , getAuditLogTiming     :: Maybe AuditLogTiming
  , getAuditLogLimit      :: Maybe Int
  } deriving ( Show, Read)

instance Default GetAuditLogOpts where
  def = GetAuditLogOpts { getAuditLogUserId     = Nothing
                        , getAuditLogActionType = Nothing
                        , getAuditLogTiming     = Nothing
                        , getAuditLogLimit      = Nothing
                        }

data AuditLogTiming = BeforeLogEntry AuditLogEntryId
                    | AfterLogEntry AuditLogEntryId
                    | LatestLogEntries
  deriving (Show, Read, Eq, Ord)

-- | See <https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events> for more information on Events
toAuditLogEvent :: Int -> Maybe AuditLogEvent
toAuditLogEvent i = if i `elem` (1 : 121 : [10..15] <> [20..42] <> [50..52] <> [60..62] <> [72..75] <> [80..85] <> [90..92] <> [100..102] <> [110..112] <> [140..145] <> [150, 151])
  then Just (MkAuditLogEvent i) else Nothing


guildMembersTimingToQuery :: GuildMembersTiming -> R.Option 'R.Https
guildMembersTimingToQuery (GuildMembersTiming mLimit mAfter) =
  let limit = case mLimit of
              Nothing -> mempty
              Just lim -> "limit" R.=: lim
      after = case mAfter of
              Nothing -> mempty
              Just aft -> "after" R.=: show aft
  in limit <> after

guildMajorRoute :: GuildRequest a -> String
guildMajorRoute c = case c of
  (GetGuild g) ->                         "guild " <> show g
  (ModifyGuild g _) ->                    "guild " <> show g
  (DeleteGuild g) ->                      "guild " <> show g
  (GetGuildChannels g) ->            "guild_chan " <> show g
  (CreateGuildChannel g _ _ _) ->    "guild_chan " <> show g
  (ModifyGuildChannelPositions g _) -> "guild_chan " <> show g
  (ListActiveGuildThreads g) ->      "guild_chan " <> show g
  (GetGuildMember g _) ->            "guild_memb " <> show g
  (ListGuildMembers g _) ->         "guild_membs " <> show g
  (AddGuildMember g _ _) ->         "guild_membs " <> show g
  (ModifyGuildMember g _ _) ->      "guild_membs " <> show g
  (ModifyCurrentUserNick g _) ->    "guild_membs " <> show g
  (AddGuildMemberRole g _ _) ->     "guild_membs " <> show g
  (RemoveGuildMemberRole g _ _) ->  "guild_membs " <> show g
  (RemoveGuildMember g _) ->        "guild_membs " <> show g
  (GetGuildBan g _) ->               "guild_bans " <> show g
  (GetGuildBans g) ->                "guild_bans " <> show g
  (CreateGuildBan g _ _) ->           "guild_ban " <> show g
  (RemoveGuildBan g _) ->             "guild_ban " <> show g
  (GetGuildRoles g) ->              "guild_roles " <> show g
  (CreateGuildRole g _) ->          "guild_roles " <> show g
  (ModifyGuildRolePositions g _) -> "guild_roles " <> show g
  (ModifyGuildRole g _ _) ->         "guild_role " <> show g
  (DeleteGuildRole g _) ->           "guild_role " <> show g
  (GetGuildPruneCount g _) ->       "guild_prune " <> show g
  (GetGuildAuditLog g _) ->               "guild " <> show g
  (BeginGuildPrune g _) ->          "guild_prune " <> show g
  (GetGuildVoiceRegions g) ->       "guild_voice " <> show g
  (GetGuildInvites g) ->            "guild_invit " <> show g
  (GetGuildIntegrations g) ->       "guild_integ " <> show g
  (CreateGuildIntegration g _ _) -> "guild_integ " <> show g
  (ModifyGuildIntegration g _ _) -> "guild_intgr " <> show g
  (DeleteGuildIntegration g _) ->   "guild_intgr " <> show g
  (SyncGuildIntegration g _) ->      "guild_sync " <> show g
  (GetGuildWidget g) ->            "guild_widget " <> show g
  (ModifyGuildWidget g _) ->       "guild_widget " <> show g
  (GetGuildVanityURL g) ->                "guild " <> show g


guilds :: R.Url 'R.Https
guilds = baseUrl /: "guilds"

guildJsonRequest :: GuildRequest r -> JsonRequest
guildJsonRequest c = case c of
  (GetGuild guild) ->
      Get (guilds /~ guild) mempty

  (ModifyGuild guild patch) ->
      Patch (guilds /~ guild) (pure (R.ReqBodyJson patch)) mempty

  (DeleteGuild guild) ->
      Delete (guilds /~ guild) mempty

  (GetGuildChannels guild) ->
      Get (guilds /~ guild /: "channels") mempty

  (CreateGuildChannel guild name perms patch) ->
      Post (guilds /~ guild /: "channels")
           (pure (R.ReqBodyJson (createChannelOptsToJSON name perms patch))) mempty

  (ModifyGuildChannelPositions guild newlocs) ->
      let patch = map (\(a, b) -> object [("id", toJSON a)
                                         ,("position", toJSON b)]) newlocs
      in Patch (guilds /~ guild /: "channels") (pure (R.ReqBodyJson patch)) mempty

  (ListActiveGuildThreads guild) ->
      Get (guilds /~ guild /: "threads" /: "active") mempty

  (GetGuildMember guild member) ->
      Get (guilds /~ guild /: "members" /~ member) mempty

  (ListGuildMembers guild range) ->
      Get (guilds /~ guild /: "members") (guildMembersTimingToQuery range)

  (AddGuildMember guild user patch) ->
      Put (guilds /~ guild /: "members" /~ user) (R.ReqBodyJson patch) mempty

  (ModifyGuildMember guild member patch) ->
      Patch (guilds /~ guild /: "members" /~ member) (pure (R.ReqBodyJson patch)) mempty

  (ModifyCurrentUserNick guild name) ->
      let patch = object ["nick" .= name]
      in Patch (guilds /~ guild /: "members/@me/nick") (pure (R.ReqBodyJson patch)) mempty

  (AddGuildMemberRole guild user role) ->
      let body = R.ReqBodyJson (object [])
      in Put (guilds /~ guild /: "members" /~ user /: "roles" /~ role) body mempty

  (RemoveGuildMemberRole guild user role) ->
      Delete (guilds /~ guild /: "members" /~ user /: "roles" /~ role) mempty

  (RemoveGuildMember guild user) ->
      Delete (guilds /~ guild /: "members" /~ user) mempty

  (GetGuildBan guild user) -> Get (guilds /~ guild /: "bans" /~ user) mempty

  (GetGuildBans guild) -> Get (guilds /~ guild /: "bans") mempty

  (CreateGuildBan guild user patch) ->
      Put (guilds /~ guild /: "bans" /~ user) (R.ReqBodyJson patch) mempty

  (RemoveGuildBan guild ban) ->
      Delete (guilds /~ guild /: "bans" /~ ban) mempty

  (GetGuildRoles guild) ->
      Get (guilds /~ guild /: "roles") mempty

  (CreateGuildRole guild patch) ->
      Post (guilds /~ guild /: "roles") (pure (R.ReqBodyJson patch)) mempty

  (ModifyGuildRolePositions guild patch) ->
      let body = map (\(role, pos) -> object ["id".=role, "position".=pos]) patch
      in Patch (guilds /~ guild /: "roles") (pure (R.ReqBodyJson body)) mempty

  (ModifyGuildRole guild role patch) ->
      Patch (guilds /~ guild /: "roles" /~ role) (pure (R.ReqBodyJson patch)) mempty

  (DeleteGuildRole guild role) ->
      Delete (guilds /~ guild /: "roles" /~ role) mempty

  (GetGuildPruneCount guild days) ->
      Get (guilds /~ guild /: "prune") ("days" R.=: days)

  (GetGuildAuditLog guild auditOpts) ->
      let user_id = case getAuditLogUserId auditOpts of
            Nothing  -> mempty
            Just uid -> "user_id" R.=: uid
          action_type = case getAuditLogActionType auditOpts of
            Nothing                  -> mempty
            Just (MkAuditLogEvent n) -> "action_type" R.=: n

          timing = case getAuditLogTiming auditOpts of
            Nothing                    -> mempty
            Just LatestLogEntries      -> mempty
            Just (BeforeLogEntry snow) -> "before" R.=: snow
            Just (AfterLogEntry snow)  -> "after"  R.=: snow

          limit = case getAuditLogLimit auditOpts of
            Nothing -> mempty
            Just n  -> "limit" R.=: max 1 (min 100 n)
      
          body = user_id <> action_type <> timing <> limit
      in Get (guilds /~ guild /: "audit-logs") body

  (BeginGuildPrune guild days) ->
      Post (guilds /~ guild /: "prune") (pure R.NoReqBody) ("days" R.=: days)

  (GetGuildVoiceRegions guild) ->
      Get (guilds /~ guild /: "regions") mempty

  (GetGuildInvites guild) ->
      Get (guilds /~ guild /: "invites") mempty

  (GetGuildIntegrations guild) ->
      Get (guilds /~ guild /: "integrations") mempty

  (CreateGuildIntegration guild iid opts) ->
      let patch = object ["type" .= createGuildIntegrationOptsType opts, "id" .= iid]
      in Post (guilds /~ guild /: "integrations") (pure (R.ReqBodyJson patch)) mempty

  (ModifyGuildIntegration guild iid patch) ->
      let body = pure (R.ReqBodyJson patch)
      in Patch (guilds /~ guild /: "integrations" /~ iid) body mempty

  (DeleteGuildIntegration guild integ) ->
      Delete (guilds /~ guild /: "integrations" /~ integ) mempty

  (SyncGuildIntegration guild integ) ->
      Post (guilds /~ guild /: "integrations" /~ integ) (pure R.NoReqBody) mempty

  (GetGuildWidget guild) ->
      Get (guilds /~ guild /: "integrations") mempty

  (ModifyGuildWidget guild patch) ->
      Patch (guilds /~ guild /: "widget") (pure (R.ReqBodyJson patch)) mempty

  (GetGuildVanityURL guild) ->
      Get (guilds /~ guild /: "vanity-url") mempty

