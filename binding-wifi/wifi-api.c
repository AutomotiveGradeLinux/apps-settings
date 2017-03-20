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
 * \file
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



static int need_passkey_flag = 0;
static int passkey_not_correct_flag = 0;

char *passkey;
callback ptr_my_callback;
callback wifiListChanged_clbck;

GSList *wifi_list = NULL;


/**
 * \brief Input the passkey for connection to AP.
 *
 * \param[in] passkey pasword for the network
 *
 * The user should first subscribe for the event 'passkey' and then provide passkey
 * when this event has been received.
 *
 * */
void wifi_passkey(struct afb_req request) {


    const char *passkey_from_user;

    /* retrieves the argument, expects passkey string */
    passkey_from_user = afb_req_value(request, "passkey");

    NOTICE(afbitf, "Passkey inserted: %s\n", passkey_from_user);

    sendPasskey(passkey_from_user);


    if (passkey != NULL) {

        registerPasskey(passkey);
    } else {
        NOTICE(afbitf, "Please enter the passkey first\n");

    }
}



struct event
{
    struct event *next;
    struct afb_event event;
    char tag[1];
};

static struct event *events = 0;

/**
 * \internal
 * \brief Helper function that searches for a specific event.
 *
 * \param[in] tag of the event
 */
static struct event *event_get(const char *tag)
{
    struct event *e = events;
    while(e && strcmp(e->tag, tag))
        e = e->next;
    return e;
}

/**
 * \internal
 * \brief Helper function that actually pushes the event.
 *
 * \param[in] tag of the event
 * \param[in] *args json object that contains data for the event
 *
 */
static int do_event_push(struct json_object *args, const char *tag)
{
    struct event *e;
    e = event_get(tag);
    return e ? afb_event_push(e->event, json_object_get(args)) : -1;
}

/**
 * \internal
 * \brief Pushes the event of 'tag' with the 'data
 *
 * \param[in] tag
 * \param[in] data
 *
 */
static void eventpush (struct afb_req request)
{
    const char *tag = afb_req_value(request, "tag");
    const char *data = afb_req_value(request, "data");
    json_object *object = data ? json_tokener_parse(data) : NULL;

    if (tag == NULL)
        afb_req_fail(request, "failed", "bad arguments");
    else if (0 > do_event_push(object, tag))
        afb_req_fail(request, "failed", "push error");
    else
        afb_req_success(request, NULL, NULL);
}

/**
 *
 * \brief Notify user that passkey is necessary.
 *
 * \param[in] number additional integer data produced by Agent
 * \param[in] asciidata additional ascii data produced by Agent
 *
 * This function is called from the registered agent on RequestInput() call.
 *
 */
void ask_for_passkey(int number, const char* asciidata) {
    NOTICE(afbitf, "Passkey for %s network needed.", asciidata);
    NOTICE(afbitf, "Sending event.");

    json_object *jresp = json_object_new_object();

    json_object *int1 = json_object_new_int(number);
    json_object *string = json_object_new_string(asciidata);

    json_object_object_add(jresp, "data1", int1);
    json_object_object_add(jresp, "data2", string);


    do_event_push(jresp, "passkey");
}

/**
 * \internal
 * \brief Notify GUI that wifi list has changed.
 *
 * \param[in] number number of event that caused the callback
 * \param[in] asciidata additional data, e.g "BSSRemoved"
 *
 * User should first subscribe for the event 'networkList' and then wait for this event.
 * When notification comes, update the list if networks by scan_result call.
 *
 */
void wifiListChanged(int number, const char* asciidata) {

    //WARNING(afbitf, "wifiListChanged, reason:%d, %s",number, asciidata );


    json_object *jresp = json_object_new_object();

    json_object *int1 = json_object_new_int(number);
    json_object *string = json_object_new_string(asciidata);

    json_object_object_add(jresp, "data1", int1);
    json_object_object_add(jresp, "data2", string);

    do_event_push(jresp, "networkList");



}


/**
 * \brief Initializes the binder and activates the WiFi HW, should be called first.
 *
 * \param[in] request no specific data needed
 *
 * \return result of the request, either "success" or "failed" with description of error
 *
 * This will fail if
 * 	- agent for handling passkey requests cannot be registered
 * 	- some error is returned from connman
 */
static void wifi_activate(struct afb_req request) /*AFB_SESSION_CHECK*/
{
	json_object *jresp;
	GError *error = NULL;

	if (ptr_my_callback == NULL) {

        ptr_my_callback = ask_for_passkey;
        register_callbackSecurity(ptr_my_callback);

	}

    if (wifiListChanged_clbck == NULL) {

        wifiListChanged_clbck = wifiListChanged;
        register_callbackWiFiList(wifiListChanged_clbck);

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
 * \brief Deinitializes the binder and deactivates the WiFi HW.
 *
 * \param[in] request no specific data needed
 *
 * \return result of the request, either "success" or "failed" with description of error
 *
 * This will fail if
 * 	- agent for handling passkey requests cannot be unregistered
 * 	- some error is returned from connman
 *
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
 * \brief Starts scan for access points.
 *
 * \param[in] request no specific data needed
 *
 * \return result of the request, either "success" or "failed" with description of error
 *
 * User should first subscribe for the event 'networkList' and then wait for event to come.
 * When notification comes, update the list of networks by scan_result call.
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
 * \brief Return network list.
 *
 * \param[in] request no specific data needed
 *
 * \return result of the request, either "success" or "failed" with description of error \n
 * 		   result is array of following json objects: Number, Strength, ESSID, Security, IPAddress, State.
 * 		   E.g. {"Number":0,"Strength":82,"ESSID":"wifidata02","Security":"ieee8021x","IPAddress":"unsigned","State":"idle"}, or \n
 * 		   {"Number":1,"Strength":51,"ESSID":"ALCZM","Security":"WPA-PSK","IPAddress":"192.168.1.124","State":"ready"}
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
    unsigned int strength = 0;
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

            DEBUG(afbitf, "The object json: %s\n", json_object_to_json_string(jresp));

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
			holdMe = list->next;
			g_free(list);
			list = holdMe;
		}
		afb_req_success(request, my_array, "Wi-Fi - Scan Result is Displayed");
	} else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief Connects to a specific network.
 *
 * \param[in] request Number of network to connect to.
 *
 * \return result of the request, either "success" or "failed" with description of error
 *
 * Specify number of network to connect to obtained by scan_result().
 * User should first subscribe for the event 'passkey', if passkey
 * is needed for connection this event is pushed.
 *
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
        NOTICE(afbitf,"Joining network number %d\n", network_index);


	}

	//get information about desired network
	item = g_slist_nth_data(wifi_list, network_index);

	if (item == NULL) {
		//Index starts from 1
        ERROR(afbitf, "Network with number %d not found.\n", network_index + 1);
		//TODO:better error message
		afb_req_fail(request, "failed", "bad arguments");
	}

	else {
		wifiProfileToConnect = (struct wifi_profile_info *) item;
        INFO(afbitf, "Name: %s, strength: %d, %s\n", wifiProfileToConnect->ESSID,
				wifiProfileToConnect->Strength,
				wifiProfileToConnect->NetworkPath);
	}
	error = do_connectNetwork(wifiProfileToConnect->NetworkPath);

	if (error == NULL)
		afb_req_success(request, NULL, NULL);

	else if (passkey_not_correct_flag) {
		need_passkey_flag = 0;
		passkey_not_correct_flag = 0;
		afb_req_fail(request, "passkey-incorrect", NULL);
	} else if (need_passkey_flag) {
		need_passkey_flag = 0;
		afb_req_fail(request, "need-passkey", NULL);

	} else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief Disconnects from a network.
 *
 * \param[in] request number of network to disconnect from
 *
 * \return result of the request, either "success" or "failed" with description of error
 *
 * Specify number of network to disconnect from obtained by scan_result().
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
        NOTICE(afbitf, "Joining network number %d\n", network_index);

	}

	//get information about desired network
	item = g_slist_nth_data(wifi_list, network_index);

	if (item == NULL) {
		//Index starts from 1
        ERROR(afbitf,"Network with number %d not found.\n", network_index + 1);
		//TODO:better error message
		afb_req_fail(request, "failed", "bad arguments");
	}

	else {
		wifiProfileToConnect = (struct wifi_profile_info *) item;
        INFO(afbitf, "Name: %s, strength: %d, %s\n", wifiProfileToConnect->ESSID,
				wifiProfileToConnect->Strength,
				wifiProfileToConnect->NetworkPath);
	}
	error = do_disconnectNetwork(wifiProfileToConnect->NetworkPath);

	if (error == NULL)
		afb_req_success(request, NULL, NULL);
	else
		afb_req_fail(request, "failed", error->message);
}

/**
 * \brief Return current status of a connection.
 *
 * \param[in] request no specific data needed
 *
 * \return result of the request, either "success" with status or "failed" with description of error
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
            DEBUG(afbitf, "Wi-Fi OFF\n");
		} else {/*Wi-Fi is ON*/
			json_object_object_add(jresp, "Power",
					json_object_new_string("ON"));
			if (status->connected == 0) {/*disconnected*/
				json_object_object_add(jresp, "Connection",
						json_object_new_string("Disconnected"));
                DEBUG(afbitf, "Wi-Fi ON - Disconnected \n");
			} else {/*Connected*/
				json_object_object_add(jresp, "Connection",
						json_object_new_string("Connected"));
                DEBUG(afbitf, "Wi-Fi ON - Connected \n");
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



/**
 * \internal
 * \brief Helper functions that actually delete the tag.
 *
 * \param[in] tag tag to delete
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static int event_del(const char *tag)
{
    struct event *e, **p;

    /* check exists */
    e = event_get(tag);
    if (!e) return -1;

    /* unlink */
    p = &events;
    while(*p != e) p = &(*p)->next;
    *p = e->next;

    /* destroys */
    afb_event_drop(e->event);
    free(e);
    return 0;
}

/**
 * \internal
 * \brief Helper functions that actually creates event of the tag.
 *
 * \param[in] tag tag to add
 * \param[in] name name to add
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static int event_add(const char *tag, const char *name)
{
    struct event *e;

    /* check valid tag */
    e = event_get(tag);
    if (e) return -1;

    /* creation */
    e = malloc(strlen(tag) + sizeof *e);
    if (!e) return -1;
    strcpy(e->tag, tag);

    /* make the event */
    e->event = afb_daemon_make_event(afbitf->daemon, name);
    if (!e->event.closure) { free(e); return -1; }

    /* link */
    e->next = events;
    events = e;
    return 0;
}

/**
 * \brief Creates event of the tag.
 *
 * \param[in] request tag and name of the event
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static void eventadd (struct afb_req request)
{
    const char *tag = afb_req_value(request, "tag");
    const char *name = afb_req_value(request, "name");

    json_object *query = afb_req_json(request);

    if (tag == NULL || name == NULL)
        afb_req_fail(request, "failed", "bad arguments");
    else if (0 != event_add(tag, name))
        afb_req_fail(request, "failed", "creation error");
    else
        afb_req_success(request, NULL, NULL);
}

/**
 * \brief Deletes the event of tag.
 *
 * \param[in] request tag to delete
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static void eventdel (struct afb_req request)
{
    const char *tag = afb_req_value(request, "tag");

    if (tag == NULL)
        afb_req_fail(request, "failed", "bad arguments");
    else if (0 != event_del(tag))
        afb_req_fail(request, "failed", "deletion error");
    else
        afb_req_success(request, NULL, NULL);
}


/**
 * \internal
 * \brief Helper functions to subscribe for the event of tag.
 *
 * \param[in] request tag to subscribe for
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static int event_subscribe(struct afb_req request, const char *tag)
{
    struct event *e;
    e = event_get(tag);
    return e ? afb_req_subscribe(request, e->event) : -1;
}

/**
 * \internal
 * \brief Helper functions to unsubscribe for the event of tag.
 *
 * \param[in] request tag to unsubscribe for
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static int event_unsubscribe(struct afb_req request, const char *tag)
{
    struct event *e;
    e = event_get(tag);
    return e ? afb_req_unsubscribe(request, e->event) : -1;
}


/**
 * \brief Subscribes for the event of tag.
 *
 * \param[in] request tag to subscribe for
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static void eventsub (struct afb_req request)
{
    const char *tag = afb_req_value(request, "tag");

    if (tag == NULL)
        afb_req_fail(request, "failed", "bad arguments");
    else if (0 != event_subscribe(request, tag))
        afb_req_fail(request, "failed", "subscription error");
    else
        afb_req_success(request, NULL, NULL);
}


/**
 * \brief Unsubscribes for the event of tag.
 *
 * \param[in] request tag to unsubscribe for
 *
 * \return result of the request, either "success" or "failed" with description of error
 */
static void eventunsub (struct afb_req request)
{
    const char *tag = afb_req_value(request, "tag");

    if (tag == NULL)
        afb_req_fail(request, "failed", "bad arguments");
    else if (0 != event_unsubscribe(request, tag))
        afb_req_fail(request, "failed", "unsubscription error");
    else
        afb_req_success(request, NULL, NULL);
}


/*
 * array of the verbs exported to afb-daemon
 */
static const struct afb_verb_desc_v1 binding_verbs[] = {
/* VERB'S NAME     			SESSION MANAGEMENT          	FUNCTION TO CALL  					SHORT DESCRIPTION */
{ .name = "activate", 	  .session = AFB_SESSION_NONE, .callback = wifi_activate, 	.info = "Activate Wi-Fi" },
{ .name = "deactivate",   .session = AFB_SESSION_NONE, .callback = wifi_deactivate, .info ="Deactivate Wi-Fi" },
{ .name = "scan", 		  .session = AFB_SESSION_NONE, .callback = wifi_scan, 		.info ="Scanning Wi-Fi" },
{ .name = "scan_result",  .session = AFB_SESSION_NONE, .callback = wifi_scanResult,	.info = "Get scan result Wi-Fi" },
{ .name = "connect", 	  .session = AFB_SESSION_NONE, .callback = wifi_connect, 	.info ="Connecting to Access Point" },
{ .name = "status", 	  .session = AFB_SESSION_NONE, .callback = wifi_status, 	.info ="Check connection status" },
{ .name = "disconnect",   .session = AFB_SESSION_NONE, .callback = wifi_disconnect, .info ="Disconnecting connection" },
{ .name = "reconnect", 	  .session = AFB_SESSION_NONE, .callback = wifi_reconnect, 	.info ="Reconnecting to Access Point" },
{ .name = "insertpasskey",.session = AFB_SESSION_NONE, .callback = wifi_passkey,    .info ="inputs the passkey after it has been requsted"},
{ .name = "eventadd",     .session = AFB_SESSION_NONE, .callback = eventadd,        .info ="adds the event of 'name' for the 'tag'"},
{ .name = "eventsub",     .session = AFB_SESSION_NONE, .callback = eventsub,        .info ="unsubscribes to the event of 'tag'"},
{ .name = "eventpush",    .session = AFB_SESSION_NONE, .callback = eventpush,       .info ="pushes the event of 'tag' with the 'data'"},
{ .name = "eventunsub",   .session = AFB_SESSION_NONE, .callback = eventunsub,      .info ="unsubscribes to the event of 'tag'"},
{ .name = "eventdel",     .session = AFB_SESSION_NONE, .callback = eventdel,        .info ="deletes the event of 'tag'"},

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

