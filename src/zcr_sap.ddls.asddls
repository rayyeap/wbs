@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: WBS SAP'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCR_SAP
  as select from zta_sap
  association to parent ZCR_REQUEST   as _Request on $projection.RequestUuid = _Request.RequestUuid
  composition [0..*] of ZCR_SAP_ITEMS as _Sapitems
{
  key sap_uuid              as SapUuid,
      parent_uuid           as RequestUuid,
      sap_id                as SapId,

      project_definition    as projectdefinition,
      project_description   as projectdescription,
      project_profile       as projectprofile,
      company_code          as companycode,
      plant                 as plant,
      profit_center         as profitcenter,
      functional_area       as functionalarea,
      person_responsible_no as personresponsibleno,
      start_date            as startdate,
      finish_date           as finishdate,
      joint_venture_id      as jointventureid,
      recovery_indicator    as recoveryindicator,
      equity_type           as equitytype,
      jv_object_type        as jvobjecttype,
      jv_jib_class          as jvjibclass,
      jv_jib_sa_class       as jvjibsaclass,
      //local ETag field --> OData ETag
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      //Associations
      _Request,
      _Sapitems
}
