@EndUserText.label: 'Read company code data via RFC'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_COMPANYCODE_VIA_RFC'

define root custom entity zce_companycode
{
 @UI.facet     : [
        {
          id        :       'CompanyCode',
          purpose   :  #STANDARD,
          type      :     #IDENTIFICATION_REFERENCE,
          label     :    'Company Code',
          position  : 10 }
      ]
      
      @UI       : {
      lineItem  : [{position: 10, importance: #HIGH}],
      identification: [{position: 10}],
     selectionField: [{position: 10}]
      }
  key comp_code : abap.char(4);
  
      @UI       : {
      lineItem  : [{position: 20, importance: #HIGH}],
      identification: [{position: 20}],
      selectionField: [{position: 20}]
      }
      comp_name : abap.char(25);
}
