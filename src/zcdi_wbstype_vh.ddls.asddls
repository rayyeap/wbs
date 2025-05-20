@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_WBSTYPE_QUERY'
define custom entity ZCDI_WBSTYPE_VH
{
    @EndUserText.label: 'WBS Type'
    key wbstype : abap.char(10);

}
