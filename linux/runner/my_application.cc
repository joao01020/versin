#include "my_application.h"

#include <flutter_linux/flutter_linux.h>

#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

// ============================================================
// DESKTOP MULTI WINDOW
// ============================================================

#include "desktop_multi_window/desktop_multi_window_plugin.h"

// ============================================================
// APPLICATION
// ============================================================

struct _MyApplication
{
  GtkApplication parent_instance;

  char **dart_entrypoint_arguments;
};

G_DEFINE_TYPE(
    MyApplication,
    my_application,
    GTK_TYPE_APPLICATION)

// ============================================================
// PRIMEIRO FRAME
// ============================================================
//
// A janela só é mostrada depois que o primeiro frame Flutter
// estiver pronto.
//
// ============================================================

static void first_frame_cb(
    MyApplication *self,
    FlView *view)
{
  gtk_widget_show(
      gtk_widget_get_toplevel(
          GTK_WIDGET(view)));
}

// ============================================================
// ACTIVATE
// ============================================================

static void my_application_activate(
    GApplication *application)
{
  MyApplication *self =
      MY_APPLICATION(application);

  GtkWindow *window =
      GTK_WINDOW(
          gtk_application_window_new(
              GTK_APPLICATION(application)));

  // ==========================================================
  // HEADER BAR
  // ==========================================================
  //
  // Em GNOME/Wayland usamos GtkHeaderBar.
  //
  // Em X11 fora do GNOME mantemos a barra tradicional para
  // melhor compatibilidade com outros window managers.
  //
  // ==========================================================

  gboolean use_header_bar =
      TRUE;

#ifdef GDK_WINDOWING_X11

  GdkScreen *screen =
      gtk_window_get_screen(
          window);

  if (GDK_IS_X11_SCREEN(
          screen))
  {
    const gchar *wm_name =
        gdk_x11_screen_get_window_manager_name(
            screen);

    if (g_strcmp0(
            wm_name,
            "GNOME Shell") !=
        0)
    {
      use_header_bar =
          FALSE;
    }
  }

#endif

  if (use_header_bar)
  {
    GtkHeaderBar *header_bar =
        GTK_HEADER_BAR(
            gtk_header_bar_new());

    gtk_widget_show(
        GTK_WIDGET(
            header_bar));

    gtk_header_bar_set_title(
        header_bar,
        "versin");

    gtk_header_bar_set_show_close_button(
        header_bar,
        TRUE);

    gtk_window_set_titlebar(
        window,
        GTK_WIDGET(
            header_bar));
  }
  else
  {
    gtk_window_set_title(
        window,
        "versin");
  }

  // ==========================================================
  // TAMANHO PADRÃO DA JANELA PRINCIPAL
  // ==========================================================

  gtk_window_set_default_size(
      window,
      1280,
      720);

  // ==========================================================
  // PROJETO FLUTTER
  // ==========================================================

  g_autoptr(FlDartProject) project =
      fl_dart_project_new();

  fl_dart_project_set_dart_entrypoint_arguments(
      project,
      self->dart_entrypoint_arguments);

  // ==========================================================
  // FLUTTER VIEW
  // ==========================================================

  FlView *view =
      fl_view_new(
          project);

  GdkRGBA background_color;

  gdk_rgba_parse(
      &background_color,
      "#000000");

  fl_view_set_background_color(
      view,
      &background_color);

  gtk_widget_show(
      GTK_WIDGET(
          view));

  gtk_container_add(
      GTK_CONTAINER(
          window),
      GTK_WIDGET(
          view));

  // ==========================================================
  // MOSTRAR APÓS PRIMEIRO FRAME
  // ==========================================================

  g_signal_connect_swapped(
      view,
      "first-frame",
      G_CALLBACK(
          first_frame_cb),
      self);

  gtk_widget_realize(
      GTK_WIDGET(
          view));

  // ==========================================================
  // REGISTRAR PLUGINS DA JANELA PRINCIPAL
  // ==========================================================

  fl_register_plugins(
      FL_PLUGIN_REGISTRY(
          view));

  // ==========================================================
  // REGISTRAR PLUGINS NAS NOVAS JANELAS
  // ==========================================================
  //
  // ESSENCIAL PARA desktop_multi_window.
  //
  // Toda nova janela criada pelo plugin possui outro engine
  // Flutter. Esse callback registra os plugins também nesse
  // novo engine.
  //
  // Sem isso:
  //
  // - a janela externa pode não abrir corretamente;
  // - MethodChannels podem falhar;
  // - outros plugins usados pela subjanela podem não existir.
  //
  // ==========================================================

  desktop_multi_window_plugin_set_window_created_callback(
      [](FlPluginRegistry *registry)
      {
        fl_register_plugins(
            registry);
      });

  // ==========================================================
  // FOCO
  // ==========================================================

  gtk_widget_grab_focus(
      GTK_WIDGET(
          view));
}

// ============================================================
// LOCAL COMMAND LINE
// ============================================================

static gboolean my_application_local_command_line(
    GApplication *application,
    gchar ***arguments,
    int *exit_status)
{
  MyApplication *self =
      MY_APPLICATION(
          application);

  // ==========================================================
  // ARGUMENTOS DART
  // ==========================================================
  //
  // O primeiro argumento é o nome do executável.
  //
  // Os demais são enviados para o entrypoint Dart.
  //
  // Isso também é importante para as janelas secundárias
  // identificarem seus argumentos.
  //
  // ==========================================================

  self->dart_entrypoint_arguments =
      g_strdupv(
          *arguments +
          1);

  g_autoptr(GError) error =
      nullptr;

  if (!g_application_register(
          application,
          nullptr,
          &error))
  {
    g_warning(
        "Failed to register: %s",
        error->message);

    *exit_status =
        1;

    return TRUE;
  }

  g_application_activate(
      application);

  *exit_status =
      0;

  return TRUE;
}

// ============================================================
// STARTUP
// ============================================================

static void my_application_startup(
    GApplication *application)
{
  // ==========================================================
  // STARTUP PADRÃO
  // ==========================================================

  G_APPLICATION_CLASS(
      my_application_parent_class)
      ->startup(
          application);
}

// ============================================================
// SHUTDOWN
// ============================================================

static void my_application_shutdown(
    GApplication *application)
{
  // ==========================================================
  // SHUTDOWN PADRÃO
  // ==========================================================

  G_APPLICATION_CLASS(
      my_application_parent_class)
      ->shutdown(
          application);
}

// ============================================================
// DISPOSE
// ============================================================

static void my_application_dispose(
    GObject *object)
{
  MyApplication *self =
      MY_APPLICATION(
          object);

  g_clear_pointer(
      &self->dart_entrypoint_arguments,
      g_strfreev);

  G_OBJECT_CLASS(
      my_application_parent_class)
      ->dispose(
          object);
}

// ============================================================
// CLASS INIT
// ============================================================

static void my_application_class_init(
    MyApplicationClass *klass)
{
  G_APPLICATION_CLASS(
      klass)
      ->activate =
      my_application_activate;

  G_APPLICATION_CLASS(
      klass)
      ->local_command_line =
      my_application_local_command_line;

  G_APPLICATION_CLASS(
      klass)
      ->startup =
      my_application_startup;

  G_APPLICATION_CLASS(
      klass)
      ->shutdown =
      my_application_shutdown;

  G_OBJECT_CLASS(
      klass)
      ->dispose =
      my_application_dispose;
}

// ============================================================
// INSTANCE INIT
// ============================================================

static void my_application_init(
    MyApplication *self)
{
}

// ============================================================
// CREATE APPLICATION
// ============================================================

MyApplication *
my_application_new()
{
  // ==========================================================
  // PROGRAM NAME
  // ==========================================================

  g_set_prgname(
      APPLICATION_ID);

  // ==========================================================
  // APPLICATION
  // ==========================================================
  //
  // G_APPLICATION_NON_UNIQUE é importante aqui porque o Versin
  // precisa permitir múltiplas janelas/processos associados.
  //
  // ==========================================================

  return MY_APPLICATION(
      g_object_new(
          my_application_get_type(),
          "application-id",
          APPLICATION_ID,
          "flags",
          G_APPLICATION_NON_UNIQUE,
          nullptr));
}