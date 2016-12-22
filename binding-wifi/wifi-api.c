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

/**
 * file
 *
 * \brief Implementation of WiFi Binder for AGL's App Framework
 *
 * \author ALPS Electric
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <json-c/json.h>
#include <afb/afb-binding.h>

#include "wifi-api.h"
#include "wifi-connman.h"

/*
 * the interface to afb-daemon
 */
const struct afb_binding_interface *afbitf;

static int need_password_flag = 0;
static int password_not_correct_flag = 0;

char *passkey;
callback ptr_my_callback;

GSList *wifi_list = NULL;

/**
 * \brief Read out the passkey from the use and pass it to Agent
 *
 * \todo Since I do not know how to subscribe for the events from framework,
 *  it is necessary first to register the password http://IP_ADDRESS:PORT/api/wifi-manager/security?passkey=mypassword.
 *  Then this function is called automatically.
 *
 *
 * */
void passkey_inserted(void) {

	printf("Passkey inserted: %s\n", passkey);

	if (passkey != NULL) {

		registerPasskey(passkey);
	} else {
		printf("Please enter the password first\n");

	}
}

/**
 * \brief Notify user that password is necessary
 *
 * This function is called from the registered agent on RequestInput() call.
 * \todo Subscribe for this event from GUI.
 *
 * */
void ask_for_passkey(int password_rejected_flag) {
	//TODO: show network we are asking password for
	printf("Insert passkey.\n");

	if (!password_rejected_flag) {
		need_password_flag = 1;
		password_not_correct_flag = 0;
		//sleep(1);
		passkey_inserted();

	}

	else if (password_rejected_flag) {
		need_password_flag = 1;
		printf("Password not correct!\n");

	}

}

/**
 * \brief Insert passkey that will be used for connections to secured AP.
 *
 * \TODO Only temporary, user should enter the password on ask_for_passkey() callback
 *
 * */
void wifi_insertpasskey(struct afb_req request) {

	const char *passkey_from_user;

	/* retrieves the argument, expects password string */
	passkey_from_user = afb_req_value(request, "passkey");

	if (passkey_from_user == NULL) {
		//TODO:better error message
		afb_req_fail(request, "failed", "specify a security key");

	} else {

		passkey = g_try_malloc0(256);
		strcpy(passkey, passkey_from_user);
		printf("Passkey is %s\n", passkey);

	}

	afb_req_success(request, NULL, NULL);
}

/**
 * \brief initialize the binder and activates the WiFi HW, should be called first
 *
 * This will fail if
 * 	- agent for handling password requests cannot be registered
 * 	- some error is returned from connman
 *
 *
 * \return result of the request, either "success" or "failed" with description
 */
static void wifi_activate(struct afb_req request) /*AFB_SESSION_CHECK*/
{
	json_object *jresp;
	GError *error = NULL;

	if (ptr_my_callback == NULL) {

		printf("Registering callback\n");

		ptr_my_callback = ask_for_passkey;
		register_callback(ptr_my_callback);

	}

	jresp = json_object_new_object();
	json_object_object_add(jresp, "activation", json_object_new_string("on"));

	error = do_wifiActivate();

	if (error == NULL) {

		afb_req_success(request, jresp, "Wi-Fi - Activated");

	} else

		afb_req_fail(request, "failed", error->message);

}

/**
 * \brief deinitialize the binder and activates the WiFi HW
 *
 * This will fail if
 * 	- agent for handling password requests cannot be unregistered
 * 	- some error is returned from connman
 *
 *
 * \return result of the request, either "success" or "failed" with description
 */
static void wifi_deactivate(struct afb_req request) /*AFB_SESSION_CHECK*/
{

	json_object *jresp;
	GError *error = NULL;

	ptr_my_callback = NULL;

	jresp = json_object_new_object();
	json_object_object_add(jresp, "deactivation", json_object_new_string("on"));

	error = do_wifiDeactivate();

	if (error == NULL) {

		afb_req_success(request, jresp, "Wi-Fi - Activated");

	} else

		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief starts scan
 *
 * \return result of the request, either "success" or "failed" with description
 */
void wifi_scan(struct afb_req request) /*AFB_SESSION_NONE*/
{
	GError *error = NULL;

	error = do_wifiScan();

	if (error == NULL) {

		afb_req_success(request, NULL, "Wi-Fi - Scan success");

	} else

		afb_req_fail(request, "failed", error->message);

}

/**
 * \brief return network list
 *
 *
 * \return result of the request, either "success" or "failed" with description
 */
void wifi_scanResult(struct afb_req request) /*AFB_SESSION_CHECK*/
{
	struct wifi_profile_info *wifiProfile = NULL;
	GSList *list = NULL;
	GSList *holdMe = NULL;
	wifi_list = NULL;
	char *essid = NULL;
	char *address = NULL;
	char *security = NULL;
	char *state = NULL;
	int strength = 0;
	int number = 0;
	GError *error = NULL;

	error = do_displayScan(&wifi_list); /*Get wifi scan list*/
	if (error == NULL) {
		json_object *my_array = json_object_new_array();

		for (list = wifi_list; list; list = list->next) { /*extract wifi scan result*/
			wifiProfile = (struct wifi_profile_info *) list->data;
			security = wifiProfile->Security.sec_type;
			strength = wifiProfile->Strength;
			//if (essid == NULL || security == NULL)
			//	continue;

			essid = wifiProfile->ESSID == NULL ?
					"HiddenSSID" : wifiProfile->ESSID;
			address =
					wifiProfile->wifiNetwork.IPaddress == NULL ?
							"unsigned" : wifiProfile->wifiNetwork.IPaddress;
			state = wifiProfile->state;
			//TODO: is there a case when security is NULL?

			json_object *int1 = json_object_new_int(number);
			json_object *int2 = json_object_new_int(strength);
			json_object *jstring1 = json_object_new_string(essid);
			json_object *jstring2 = json_object_new_string(security);
			json_object *jstring3 = json_object_new_string(address);
			json_object *jstring4 = json_object_new_string(state);

			json_object *jresp = json_object_new_object();
			json_object_object_add(jresp, "Number", int1);
			json_object_object_add(jresp, "Strength", int2);
			json_object_object_add(jresp, "ESSID", jstring1);
			json_object_object_add(jresp, "Security", jstring2);
			json_object_object_add(jresp, "IPAddress", jstring3);
			json_object_object_add(jresp, "State", jstring4);

			printf("The object json: %s\n", json_object_to_json_string(jresp));
			/*input each scan result into my_array*/
			json_object_array_add(my_array, jresp);
			number += 1;

                        //set the HMI icon according to strength, only if "ready" or "online"

                        int error = 0;
                        struct wifiStatus *status;

                        status = g_try_malloc0(sizeof(struct wifiStatus));
                        error = wifi_state(status); /*get current status of power and connection*/
                        if (!error) {

                            if (status->connected == 1) {

                               if ((strcmp(state, "ready") == 0)
                                    || ((strcmp(state, "online") == 0))) {

                                    if (strength < 30)
                                        setHMIStatus(BAR_1);
                                    else if (strength < 50)
                                        setHMIStatus(BAR_2);
                                    else if (strength < 70)
                                        setHMIStatus(BAR_3);
                                    else
                                        setHMIStatus(BAR_FULL);
                               }
                            } else
                              setHMIStatus(BAR_NO);
                      }

		}
		while (list != NULL) {
			printf("Should be freed");
			holdMe = list->next;
			g_free(list);
			list = holdMe;
		}
		afb_req_success(request, my_array, "Wi-Fi - Scan Result is Displayed");
	} else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief connects to network
 *
 * \param[in] request number of network to connect to
 *
 *	 specify number of network to connect to obtained by scan_result() like this,
 *	 http://IP_ADDRESS:PORT/api/wifi-manager/connect?network=1
 */
void wifi_connect(struct afb_req request) {

	struct wifi_profile_info *wifiProfileToConnect = NULL;

	const char *network;
	int network_index = 0;
	GError *error = NULL;
	GSList *item = NULL;

	/* retrieves the argument, expects the network number */
	network = afb_req_value(request, "network");

	if (network == NULL)
		//TODO:better error message
		afb_req_fail(request, "failed",
				"specify a network number to connect to");

	else {
		network_index = atoi(network);
		printf("Joining network number %d\n", network_index);

	}

	//get information about desired network
	item = g_slist_nth_data(wifi_list, network_index);

	if (item == NULL) {
		//Index starts from 1
		printf("Network with number %d not found.\n", network_index + 1);
		//TODO:better error message
		afb_req_fail(request, "failed", "bad arguments");
	}

	else {
		wifiProfileToConnect = (struct wifi_profile_info *) item;
		printf("Name: %s, strength: %d, %s\n", wifiProfileToConnect->ESSID,
				wifiProfileToConnect->Strength,
				wifiProfileToConnect->NetworkPath);
		//printf ("Connecting to %s\n",  wifiProfileToConnect->NetworkPath);
	}
	error = do_connectNetwork(wifiProfileToConnect->NetworkPath);

	if (error == NULL)
		afb_req_success(request, NULL, NULL);

	else if (password_not_correct_flag) {
		need_password_flag = 0;
		password_not_correct_flag = 0;
		afb_req_fail(request, "password-incorrect", NULL);
	} else if (need_password_flag) {
		need_password_flag = 0;
		afb_req_fail(request, "need-password", NULL);

	} else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief disconnect from network
 *
 * \param[in] request number of network to disconnect from
 *
 *	 specify number of network to disconnect from obtained by scan_result() like this,
 *	 http://IP_ADDRESS:PORT/api/wifi-manager/discnnect?network=1
 */
void wifi_disconnect(struct afb_req request) {

	struct wifi_profile_info *wifiProfileToConnect = NULL;

	const char *network;
	int network_index = 0;
	GError *error = NULL;
	GSList *item = NULL;

	/* retrieves the argument, expects the network number */
	network = afb_req_value(request, "network");

	if (network == NULL)
		//TODO:better error message
		afb_req_fail(request, "failed",
				"specify a network number to disconnect from");

	else {
		network_index = atoi(network);
		printf("Joining network number %d\n", network_index);

	}

	//get information about desired network
	item = g_slist_nth_data(wifi_list, network_index);

	if (item == NULL) {
		//Index starts from 1
		printf("Network with number %d not found.\n", network_index + 1);
		//TODO:better error message
		afb_req_fail(request, "failed", "bad arguments");
	}

	else {
		wifiProfileToConnect = (struct wifi_profile_info *) item;
		printf("Name: %s, strength: %d, %s\n", wifiProfileToConnect->ESSID,
				wifiProfileToConnect->Strength,
				wifiProfileToConnect->NetworkPath);
		//printf ("Connecting to %s\n",  wifiProfileToConnect->NetworkPath);
	}
	error = do_disconnectNetwork(wifiProfileToConnect->NetworkPath);

	if (error == NULL)
		afb_req_success(request, NULL, NULL);
	else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief return  current status of connection
 *
 * \return result of the request, either "success" or "failed" with description
 */
void wifi_status(struct afb_req request) {
	int error = 0;
	wifi_list = NULL;
	struct wifiStatus *status;
	json_object *jresp = json_object_new_object();

	status = g_try_malloc0(sizeof(struct wifiStatus));
	error = wifi_state(status); /*get current status of power and connection*/
	if (!error) {
		if (status->state == 0) {/*Wi-Fi is OFF*/
			json_object_object_add(jresp, "Power",
					json_object_new_string("OFF"));
			//json_object_object_add(jresp, "Connection", json_object_new_string("Disconnected"));
			printf("Wi-Fi OFF\n");
		} else {/*Wi-Fi is ON*/
			json_object_object_add(jresp, "Power",
					json_object_new_string("ON"));
			if (status->connected == 0) {/*disconnected*/
				json_object_object_add(jresp, "Connection",
						json_object_new_string("Disconnected"));
				printf("Wi-Fi ON - Disconnected \n");
			} else {/*Connected*/
				json_object_object_add(jresp, "Connection",
						json_object_new_string("Connected"));
				printf("Wi-Fi ON - Connected \n");
			}
		}
		afb_req_success(request, jresp, "Wi-Fi - Connection Status Checked");
	} else {
		afb_req_fail(request, "failed", "Wi-Fi - Connection Status unknown");
	}
}

void wifi_reconnect() {
	/*TBD*/
}



/*
 * array of the verbs exported to afb-daemon
 */
static const struct afb_verb_desc_v1 binding_verbs[] = {
/* VERB'S NAME     			SESSION MANAGEMENT          	FUNCTION TO CALL  					SHORT DESCRIPTION */
{ .name = "activate", 	.session = AFB_SESSION_NONE, 		.callback = wifi_activate, 			.info = "Activate Wi-Fi" },
{ .name = "deactivate", .session = AFB_SESSION_NONE, 		.callback = wifi_deactivate, 		.info ="Deactivate Wi-Fi" },
{ .name = "scan", 		.session = AFB_SESSION_NONE,		.callback = wifi_scan, 				.info = "Scanning Wi-Fi" },
{ .name = "scan_result",.session = AFB_SESSION_NONE, 		.callback = wifi_scanResult,		.info = "Get scan result Wi-Fi" },
{ .name = "connect", 	.session = AFB_SESSION_NONE, 		.callback = wifi_connect, 			.info ="Connecting to Access Point" },
{ .name = "status", 	.session = AFB_SESSION_NONE, 		.callback = wifi_status, 			.info ="Check connection status" },
{ .name = "disconnect", .session = AFB_SESSION_NONE, 		.callback = wifi_disconnect, 		.info ="Disconnecting connection" },
{ .name = "reconnect", 	.session = AFB_SESSION_NONE, 		.callback = wifi_reconnect, 		.info ="Reconnecting to Access Point" },
{ .name = "security", 	.session = AFB_SESSION_NONE, 		.callback = wifi_insertpasskey, 	.info ="Insert passkey" },

{ .name = NULL } /* marker for end of the array */
};

/*
 * description of the binding for afb-daemon
 */
static const struct afb_binding binding_description = {
/* description conforms to VERSION 1 */
.type = AFB_BINDING_VERSION_1, .v1 = { /* fills the v1 field of the union when AFB_BINDING_VERSION_1 */
.prefix = "wifi-manager", /* the API name (or binding name or prefix) */
.info = "wifi API", /* short description of of the binding */
.verbs = binding_verbs /* the array describing the verbs of the API */
} };

/*
 * activation function for registering the binding called by afb-daemon
 */
const struct afb_binding *afbBindingV1Register(
		const struct afb_binding_interface *itf) {
	afbitf = itf;         // records the interface for accessing afb-daemon
	return &binding_description;  // returns the description of the binding
}

