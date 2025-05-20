@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View: Approver'
@Metadata.allowExtensions: true

define view entity ZCC_APPROVER as projection on ZCR_APPROVER
{
    key ApproverUuid,
    RequestUuid,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_APPEMAIL_VH', element: 'appemail' }, useForValidation: true }]
    ApproverEmail,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZCDI_APPLEVEL_VH', element: 'applevel' }, useForValidation: true }]
    LevelName,
    LocalLastChangedAt,
    
    /* Associations */
    _Request: redirected to parent ZCC_REQUEST
}
