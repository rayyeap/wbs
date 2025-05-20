@EndUserText.label: 'Custom Entity: Approver Level'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_APPLEVEL_QUERY'
define custom entity ZCDI_APPLEVEL_VH
{
    @EndUserText.label: 'Approver Level'
    key applevel : abap.char(40);

}
