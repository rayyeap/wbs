@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: Message'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZCR_MSG 
as select from zta_msg
association to parent ZCR_REQUEST as _Request on $projection.RequestUuid = _Request.RequestUuid
{
    key logs_uuid as LogsUuid,
    parent_uuid as RequestUuid,
    sys as Sys,
    type as Type,
    message as Message,
    //local ETag field --> OData ETag
   @Semantics.systemDateTime.localInstanceLastChangedAt: true
   local_last_changed_at as LocalLastChangedAt,
    _Request // Make association public
}
