@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_REQUESTTYPE_QUERY'
define custom entity ZCDI_REQUESTTYPE_VH
{
    @EndUserText.label: 'Request Type'
    key requesttype : abap.char(50);

}
