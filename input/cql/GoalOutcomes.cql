library GoalOutcomes version '0.5.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

valueset "NCQA Goal Domains": 'http://mtnlotus.com/fhir/pco-goals/ValueSet/ncqa-goal=domains'
valueset "Goal attainment scaling score": 'http://mtnlotus.com/fhir/pco-goals/ValueSet/gas-score'

codesystem "LOINC": 'http://loinc.org'

code "GAS Baseline score": 'gas-patient-baseline' from LOINC display 'Baseline goal attainment scaling score'
code "GAS Patient follow-up score": 'gas-patient-score' from LOINC display 'Patient follow-up goal attainment scaling score'

context Patient

define "Goal Domain Observations":
  [Observation: "NCQA Goal Domains"]

define "GAS Observations":
  [Observation: "Goal attainment scaling score"]

// A "PCO Goal" is any FHIR Goal that addresses a Goal Domain Observation
// define "PCO Goals":

// A "PCO CarePlan" is any FHIR CarePlan that includes a PCO Goal
// define "PCO CarePlans":

define "GAS Baseline Score":
  [Observation: "GAS Baseline score"]

define "GAS Patient Follow-Up Score":
  [Observation: "GAS Patient follow-up score"]

// define "GAS Provider Follow-Up Score":

// define "GAS Caregiver Follow-Up Score":

define "Observations Addressed By Goals":
  [Observation] obs
    where exists obs.addressedByGoals()


// Returns a list of Observations that this Goal addresses.
define fluent function addressesObservations(goal Goal):
  goal.addresses GA
      return [Observation] C
        where C.id = GA.reference.getId()

// Returns a list of Goals that address this Observation
define fluent function addressedByGoals(obs Observation):
  [Goal] goal
    where exists ( goal.addresses GA
        where obs.id = GA.reference.getId()
    )

// Returns Date from the first Goal target that has a due date.
define fluent function dueDate(goal Goal):
  First(goal.target target
    // TODO if due is Duration, add that quantity to startDate
      let due:(target.due as FHIR.date).value
      where due is not null
      return due
  )

// Tests only the first Coding in given CodeableConcept
define fluent function findObservations(code FHIR.CodeableConcept):
  if code is null
    or code.coding is null then null 
    else [Observation] o
    where o.code ~ FHIRHelpers.ToCode ( code.coding[0])
      or exists o.component c
        where c.code ~ FHIRHelpers.ToCode ( code.coding[0])

/*
 * General FHIR data helpers.
 */

define fluent function getId(uri String):
  Last(Split(uri, '/'))