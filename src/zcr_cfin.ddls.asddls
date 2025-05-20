@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Base View: CFIN'

define view entity ZCR_CFIN
  as select from zta_cfin
  association to parent ZCR_REQUEST as _Request on  $projection.RequestUuid = _Request.RequestUuid
  composition [0..*] of ZCR_CFIN_ITEMS as _Cfinitems

{
  key cfin_uuid                  as CfinUuid,
      parent_uuid                as RequestUuid,
      cfin_id                    as CfinId,

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
      local_last_changed_at      as LocalLastChangedAt,

      //Associations
      _Request,
      _Cfinitems
      
}
