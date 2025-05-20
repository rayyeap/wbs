@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: File'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZCR_FILE
  as select from zta_file
  association to parent ZCR_REQUEST as _Request on $projection.RequestUuid = _Request.RequestUuid
{
  key file_uuid             as FileUuid,
      parent_uuid           as RequestUuid,
      @Semantics.largeObject: { mimeType: 'mimetype',   //case-sensitive
                   fileName: 'filename',   //case-sensitive
                   acceptableMimeTypes: ['text/csv'],
                   contentDispositionPreference: #ATTACHMENT }
      attachment            as Attachment,
      @Semantics.mimeType: true
      mimetype              as Mimetype,
      filename              as Filename,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Request // Make association public
}
