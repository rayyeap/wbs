@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Logs'
@Metadata.allowExtensions: true
@Search.searchable: true

define view entity ZCC_LOGS as projection on ZCR_LOGS
{
    key LogsUuid,
    RequestUuid,
    Type,
    Id,
    Msgno,
    
    @Search.defaultSearchElement: true
    Message,
    LogNo,
    LogMsgNo,
    MessageV1,
    MessageV2,
    MessageV3,
    MessageV4,
    Param,
    Line,
    Field,
    Logsys,
    LocalLastChangedAt,
    /* Associations */
    _Request: redirected to parent ZCC_REQUEST
}
