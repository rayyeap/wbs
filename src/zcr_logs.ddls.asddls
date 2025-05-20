@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: Logs'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZCR_LOGS 
as select from zta_logs
 association to parent ZCR_REQUEST as _Request on $projection.RequestUuid = _Request.RequestUuid
{
    key logs_uuid as LogsUuid,
      parent_uuid as RequestUuid,
    type as Type,
    id as Id,
    msgno as Msgno,
    message as Message,
    log_no as LogNo,
    log_msg_no as LogMsgNo,
    message_v1 as MessageV1,
    message_v2 as MessageV2,
    message_v3 as MessageV3,
    message_v4 as MessageV4,
    param as Param,
    line as Line,
    field as Field,
    logsys as Logsys,
    //local ETag field --> OData ETag
   @Semantics.systemDateTime.localInstanceLastChangedAt: true
   local_last_changed_at as LocalLastChangedAt,
    _Request // Make association public
}
