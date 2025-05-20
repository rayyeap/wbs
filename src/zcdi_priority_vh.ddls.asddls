@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PRIORITY_QUERY'
define custom entity ZCDI_PRIORITY_VH
{
    @EndUserText.label: 'Priority'
    key priority : abap.char(10);

}
