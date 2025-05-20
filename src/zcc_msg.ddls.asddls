@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Message'
@Metadata.allowExtensions: true

define view entity ZCC_MSG as projection on ZCR_MSG
{
    key LogsUuid,
    RequestUuid,
    Sys,
    Type,
    Message,
    LocalLastChangedAt,
    /* Associations */
    _Request: redirected to parent ZCC_REQUEST
}
