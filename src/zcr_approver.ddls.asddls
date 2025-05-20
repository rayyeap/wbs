@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: Approver'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCR_APPROVER
  as select from zta_approver
  association to parent ZCR_REQUEST as _Request on $projection.RequestUuid = _Request.RequestUuid
{
  key approver_uuid         as ApproverUuid,
      parent_uuid           as RequestUuid,
      approver_email        as ApproverEmail,
      level_name            as LevelName,
      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Request // Make association public
}
