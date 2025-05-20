@EndUserText.label: 'Custom Entity: Source'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SOURCE_QUERY'
define custom entity ZCDI_SOURCE_VH
{
    @EndUserText.label: 'Source System'
    @EndUserText.quickInfo: 'Currently available Source System'
    key source : abap.char(3);

}
