@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: File'
@Metadata.allowExtensions: true

define view entity ZCC_FILE as projection on ZCR_FILE
{
    key FileUuid,
    RequestUuid,
    Attachment,
    Mimetype,
    Filename,
    LocalLastChangedAt,
    /* Associations */
    _Request: redirected to parent ZCC_REQUEST
}
