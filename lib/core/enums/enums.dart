enum UserRole { patient, dietitian, admin }

enum AppointmentStatus { pending, approved, rejected, cancelled }

enum SlotStatus { available, booked, blocked }

enum Gender { female, male }

enum PatientGoal {
  loseWeight,
  gainWeight,
  stayHealthy,
  buildMuscle,
  eatBalanced,
}

enum NotificationType {
  appointmentRequested,
  appointmentApproved,
  appointmentRejected,
  dietPlanCreated,
  dietPlanUpdated,
}

enum MealCategory { breakfast, lunch, dinner, snack }
