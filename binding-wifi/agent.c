/*  Copyright 2016 ALPS ELECTRIC CO., LTD.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*/

#include <stdio.h>
#include <errno.h>

#include <gio/gio.h>
#include "wifi-connman.h"

static GMainLoop *loop = NULL;

static GDBusNodeInfo *introspection_data = NULL;

GDBusMethodInvocation *invocation_passkey = NULL;

/* Introspection data for the agent service */
static const gchar introspection_xml[] = "<node>"
		"  <interface name='net.connman.Agent'>"
		"    <method name='RequestInput'>"
		"	   <arg type='o' name='service' direction='in'/>"
		"	   <arg type='a{sv}' name='fields' direction='in'/>"
		"	   <arg type='a{sv}' name='fields' direction='out'/>"
		"    </method>"
		"    <method name='ReportError'>"
		"	   <arg type='o' name='service' direction='in'/>"
		"	   <arg type='s' name='error' direction='in'/>"
		"    </method>"
		"  </interface>"
		"</node>";

callback password_callback;

static void handle_method_call(GDBusConnection *connection, const gchar *sender,
		const gchar *object_path, const gchar *interface_name,
		const gchar *method_name, GVariant *parameters,
		GDBusMethodInvocation *invocation, gpointer user_data) {
	//MyObject *myobj = user_data;

	if (g_strcmp0(method_name, "RequestInput") == 0) {
		printf("Input requested\n");

		invocation_passkey = invocation;

		//TODO: send the  name of the network to callback

		(*password_callback)(0);

		GVariantIter *array;
		gchar * object_path;
		g_variant_get(parameters, "(oa{sv})", &object_path, &array);
		//TODO: get only object path for now, complete parameters are

		/*
		 object path "/net/connman/service/wifi_d85d4c880b1a_4c656e6f766f204b3520506c7573_managed_psk"
		 array [
		 dict entry(
		 string "Passphrase"
		 variant             array [
		 dict entry(
		 string "Type"
		 variant                      string "psk"
		 )
		 dict entry(
		 string "Requirement"
		 variant                      string "mandatory"
		 )
		 ]
		 )
		 ]
		 */
		printf("Passphrase requested for network : %s\n", object_path);

	}

	if (g_strcmp0(method_name, "ReportError") == 0) {
		printf("Error reported\n");

		gchar *error_string; // = NULL;

		gchar * object_path;
		g_variant_get(parameters, "(os)", &object_path, &error_string);

		printf("Error %s for %s\n", error_string, object_path);

		if (g_strcmp0(error_string, "invalid-key") == 0) {

			printf("Passkey is not correct.\n");
			(*password_callback)(1);

		}

	}
}

GError* sendPasskey(gchar *passkey) {

	GVariantBuilder *builder;
	GVariant *value = NULL;

	printf("Passkey to send: %s\n", passkey);

	builder = g_variant_builder_new(G_VARIANT_TYPE("a{sv}"));

	g_variant_builder_add(builder, "{sv}", "Passphrase",
			g_variant_new_string(passkey));

	value = g_variant_new("(a{sv})", builder);

	g_dbus_method_invocation_return_value(invocation_passkey, value);

	return NULL;

}

static const GDBusInterfaceVTable interface_vtable = { handle_method_call, NULL,
		NULL };

static void on_bus_acquired(GDBusConnection *connection, const gchar *name,
		gpointer user_data) {
	//MyObject *myobj = user_data;
	guint registration_id;

	registration_id = g_dbus_connection_register_object(connection,
			"/net/connman/Agent", introspection_data->interfaces[0],
			&interface_vtable, NULL, NULL, /* user_data_free_func */
			NULL); /* GError** */
	//TODO: make some proper error message rather than exiting
	//g_assert(registration_id > 0);

	return NULL;
}

void* register_agent(void *data) {

	//printf("Loop start\n");

	guint owner_id;
	//MyObject *myobj;

	introspection_data = g_dbus_node_info_new_for_xml(introspection_xml, NULL);
	g_assert(introspection_data != NULL);

	//myobj = g_object_new(my_object_get_type(), NULL);

//	owner_id = g_bus_own_name(G_BUS_TYPE_SYSTEM, "org.agent",
//			G_BUS_NAME_OWNER_FLAGS_NONE, on_bus_acquired, on_name_acquired,
//			on_name_lost, myobj,
//			NULL);

//FIXME: ALLOW_REPLACEMENT for now, make proper deinitialization
	owner_id = g_bus_own_name(G_BUS_TYPE_SYSTEM, AGENT_SERVICE,
			G_BUS_NAME_OWNER_FLAGS_REPLACE, on_bus_acquired, NULL, NULL, NULL,
			NULL);
	//G_BUS_NAME_OWNER_FLAGS_NONE G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT

	loop = g_main_loop_new(NULL, FALSE);

	//sleep(10);
	g_main_loop_run(loop);

	printf("Loop running\n");

	g_bus_unown_name(owner_id);

	g_dbus_node_info_unref(introspection_data);

	//g_object_unref(myobj);

	//printf("Loop end\n");

	return NULL;

}

GError* create_agent(GDBusConnection *connection) {

	int err = -1;
	pthread_t tid[1];

	//struct callbackData *threadData;

	err = pthread_create((&tid[0]), NULL, register_agent, NULL);

	if (err != 0) {
		printf("\ncan't create thread :[%d]", err);
		printf("Fatal error!\n\n");
		return NULL;
	}

	GVariant *message = NULL;
	GError *error = NULL;

	GVariant *params = NULL;

	char *agent_path = AGENT_PATH;

	params = g_variant_new("(o)", agent_path);

	message = g_dbus_connection_call_sync(connection, CONNMAN_SERVICE,
	CONNMAN_MANAGER_PATH, CONNMAN_MANAGER_INTERFACE, "RegisterAgent", params,
			NULL, G_DBUS_CALL_FLAGS_NONE,
			DBUS_REPLY_TIMEOUT, NULL, &error);

	if (error) {
		printf("error: %d:%s\n", error->code, error->message);

		return error;

	} else {
		printf("Agent registered\n");
		return NULL;
	}

}

GError* stop_agent(GDBusConnection *connection) {

	GVariant *message = NULL;
	GError *error = NULL;


	GVariant *params = NULL;

	char *agent_path = AGENT_PATH;


	params = g_variant_new("(o)", agent_path);

	message = g_dbus_connection_call_sync(connection, CONNMAN_SERVICE,
	CONNMAN_MANAGER_PATH, CONNMAN_MANAGER_INTERFACE, "UnregisterAgent", params,
			NULL, G_DBUS_CALL_FLAGS_NONE,
			DBUS_REPLY_TIMEOUT, NULL, &error);

	if (error) {
		printf("error: %d:%s\n", error->code, error->message);
		return error;

	} else {
		printf("Agent unregistered\n");
		return NULL;
	}

}

void register_callback(callback callback_function) {

	password_callback = callback_function;

}

