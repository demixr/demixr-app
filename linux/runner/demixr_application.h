#ifndef FLUTTER_DEMIXR_APPLICATION_H_
#define FLUTTER_DEMIXR_APPLICATION_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(DemixrApplication,
                     demixr_application,
                     DEMIXR,
                     APPLICATION,
                     GtkApplication)

/**
 * demixr_application_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #DemixrApplication.
 */
DemixrApplication* demixr_application_new();

#endif  // FLUTTER_DEMIXR_APPLICATION_H_
