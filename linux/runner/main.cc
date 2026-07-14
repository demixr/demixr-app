#include "demixr_application.h"

int main(int argc, char** argv) {
  g_autoptr(DemixrApplication) app = demixr_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
