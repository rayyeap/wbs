@EndUserText.label: 'Custom Entity: Approver Email'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_APPEMAIL_QUERY'
define custom entity ZCDI_APPEMAIL_VH
{
    @EndUserText.label: 'Approver Email'
    key appemail : abap.char(50);
     @EndUserText.label: 'Name'
        name: abap.char(100);
}
