@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Approver Draft'
@Metadata.allowExtensions: true
@Search.searchable: true

//@ObjectModel.semanticKey: ['ApproverUuid']

define view entity ZCC_APPROVER_D as projection on ZCR_APPROVER
{
    key ApproverUuid,
    RequestUuid,
    
    @Search.defaultSearchElement: true
    ApproverEmail,
    LevelName,
    LocalLastChangedAt,
    /* Associations */
    _Request : redirected to parent ZCC_REQUEST_D
}
