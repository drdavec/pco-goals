library GoalOutcomes version '0.5.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1'

codesystem "LOINC": 'http://loinc.org'
codesystem "NCQAGoalDomain": 'http://ncqa.org/fhir/pco-goals/CodeSystem/goal-domain'

valueset "NCQA Goal Domains": 'http://mtnlotus.com/fhir/pco-goals/ValueSet/ncqa-goal=domains'
valueset "Goal attainment scaling score": 'http://mtnlotus.com/fhir/pco-goals/ValueSet/gas-score'

code "GAS Baseline score": 'gas-patient-baseline' from LOINC display 'Baseline goal attainment scaling score'
code "GAS Patient follow-up score": 'gas-patient-score' from LOINC display 'Patient follow-up goal attainment scaling score'

context Patient

// For debugging
define GoalSummary: 
  [Goal] goal
    return {
      id: goal.id.value,
      dueDate: goal.dueDate(),
      pcoGoalDomains: goal.goalDomains()
    }

// For debugging
define CarPlanSummary: 
  [CarePlan] carePlan
    return {
      id: carePlan.id.value,
      pcoGoals: carePlan.pcoGoals()
    }

define "NCQA Goal Domain Observations":
  [Observation: "NCQA Goal Domains"]

define fluent function isNCQAGoalDomain(obs Observation):
  "NCQA Goal Domain Observations" contains obs

// All observations containing a Goal Attainment Scaling (GAS) score.
define "GAS Observations":
  [Observation: "Goal attainment scaling score"]

// All FHIR Goals for this patient. Useful for verifying subset matched by "PCO Goals".
define "All Goals":
  [Goal] goal

// A "PCO Goal" is any FHIR Goal that addresses a Goal Domain Observation
define "PCO Goals":
  [Goal] goal
    where exists goal.goalDomains()

// All FHIR CarePlan resources for this patient. Useful for verifying subset matched by "PCO Care Plans".
define "All Care Plans":
  [CarePlan] carePlan

// A "PCO CarePlan" is any FHIR CarePlan that includes a PCO Goal
define "PCO Care Plans":
  [CarePlan] carePlan
    where exists carePlan.pcoGoals()

// Returns a collection of Observations with a person's baseline GAS score.
define "GAS Baseline Scores":
  [Observation: "GAS Baseline score"]

// Returns a collection of Observations with a patient's follow-up GAS score.
define "GAS Patient Follow-Up Scores":
  [Observation: "GAS Patient follow-up score"]

// Returns a collection of Observations with a practitioner's follow-up GAS score.
// define "GAS Provider Follow-Up Scores":

// Returns a collection of Observations with a caregiver's follow-up GAS score.
// define "GAS Caregiver Follow-Up Scores":

// Returns a list of goal domain Observations that this Goal addresses.
define fluent function goalDomains(goal Goal):
  flatten( goal.addresses GA
      return [Observation] obs
        where obs.id = GA.reference.getId()
          and obs.isNCQAGoalDomain()
  )

// Returns a list of Observations that this Goal addresses.
define fluent function addressesObservations(goal Goal):
  flatten( goal.addresses GA
      return [Observation] obs
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

// Returns a list of PCO Goals that are included in this CarePlan.
define fluent function pcoGoals(carePlan CarePlan):
  flatten( carePlan.goal goalRef
      return [Goal] goal
        where goal.id = goalRef.reference.getId()
          and "PCO Goals" contains goal
  )

// Returns a list of Goals that address this Observation
define fluent function addressedByGoals(obs Observation):
  [Goal] goal
    where exists ( goal.addresses GA
        where obs.id = GA.reference.getId()
    )

/*
 * General FHIR data helpers.
 */

define fluent function getId(uri String):
  Last(Split(uri, '/'))