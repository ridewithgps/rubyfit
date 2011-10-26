////////////////////////////////////////////////////////////////////////////////
// The following .FIT software provided may be used with .FIT devices only and
// remains the copyrighted property of Dynastream Innovations Inc.
// The software is being provided on an "as-is" basis and as an accommodation,
// and therefore all warranties, representations, or guarantees of any kind
// (whether express, implied or statutory) including, without limitation,
// warranties of merchantability, non-infringement, or fitness for a particular
// purpose, are specifically disclaimed.
//
// Copyright 2008 Dynastream Innovations Inc.
// All rights reserved. This software may not be reproduced by any means
// without express written approval of Dynastream Innovations Inc.
////////////////////////////////////////////////////////////////////////////////

#include "stdio.h"
#include "string.h"
#include "ruby.h"
#include "math.h"

#include "fit_convert.h"

VALUE cFitParser;
VALUE cFitHandler;
VALUE cFitHandlerPrintFun;
VALUE cFitHandlerActivityFun;
VALUE cFitHandlerRecordFun;
VALUE cFitHandlerLapFun;
VALUE cFitHandlerSessionFun;
VALUE cFitHandlerDeviceInfoFun;
VALUE cFitHandlerUserProfileFun;
VALUE cFitHandlerEventFun;
VALUE cFitHandlerWeightScaleInfoFun;
static ID HANDLER_ATTR;
//garmin/dynastream, in their infinite wisdom, decided to pinch pennies on bits
//by tinkering with well established time offsets.  This is the magic number of
//seconds needed to add to their number to get the true number of seconds since
//the epoch.  For those math challenged, this is 20 years of seconds.
const GARMIN_SUCKS_OFFSET = 631065600;


void pass_message(char *msg) {
	rb_funcall(cFitHandler, cFitHandlerPrintFun, 1, rb_str_new2(msg));
}

static VALUE fit_pos_to_rb(FIT_SINT32 pos) {
	float tmp = pos * (180.0 / pow(2,31));
	tmp -= (tmp > 180.0 ? 360.0 : 0.0);
	return rb_float_new(tmp);
}


static VALUE init(VALUE self, VALUE handler) {
	cFitHandler = handler;
	rb_ivar_set(self, HANDLER_ATTR, handler);

	//callbacks
	cFitHandlerPrintFun = rb_intern("print_msg");
	cFitHandlerActivityFun = rb_intern("on_activity");
	cFitHandlerSessionFun = rb_intern("on_session");
	cFitHandlerLapFun = rb_intern("on_lap");
	cFitHandlerRecordFun = rb_intern("on_record");
	cFitHandlerEventFun = rb_intern("on_event");
	cFitHandlerDeviceInfoFun = rb_intern("on_device_info");
	cFitHandlerUserProfileFun = rb_intern("on_user_profile");
	cFitHandlerWeightScaleInfoFun = rb_intern("on_weight_scale_info");

	return Qnil;
}

static pass_activity(const FIT_ACTIVITY_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->total_timer_time != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_timer_time"), rb_float_new(mesg->total_timer_time / 1000.0));
	if(mesg->local_timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("local_timestamp"), rb_float_new(mesg->local_timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->num_sessions != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("num_sessions"), UINT2NUM(mesg->num_sessions));
	if(mesg->type != FIT_ENUM_INVALID)
		rb_hash_aset(rh, rb_str_new2("type"), UINT2NUM(mesg->type));
	if(mesg->event != FIT_ENUM_INVALID)
		rb_hash_aset(rh, rb_str_new2("event"), UINT2NUM(mesg->event));
	if(mesg->event_type != FIT_ENUM_INVALID)
		rb_hash_aset(rh, rb_str_new2("event_type"), UINT2NUM(mesg->event_type));
	if(mesg->event_group != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("event_group"), UINT2NUM(mesg->event_group));

	rb_funcall(cFitHandler, cFitHandlerActivityFun, 1, rh);
}

static pass_record(const FIT_RECORD_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->position_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("position_lat"), fit_pos_to_rb(mesg->position_lat));
	if(mesg->position_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("position_long"), fit_pos_to_rb(mesg->position_long));
	if(mesg->distance != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("distance"), rb_float_new(mesg->distance / 100.0));
	if(mesg->time_from_course != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("time_from_course"), rb_float_new(mesg->time_from_course / 1000.0));
	if(mesg->heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("heart_rate"), UINT2NUM(mesg->heart_rate));
	if(mesg->altitude != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("altitude"), rb_float_new(mesg->altitude / 5.0 - 500));
	if(mesg->speed != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("speed"), rb_float_new(mesg->speed / 1000.0));
	if(mesg->grade != FIT_SINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("grade"), rb_float_new(mesg->grade / 100.0));
	if(mesg->power != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("power"), UINT2NUM(mesg->power));
	if(mesg->cadence != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("cadence"), UINT2NUM(mesg->cadence));
	if(mesg->resistance != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("resistance"), UINT2NUM(mesg->resistance));
	if(mesg->cycle_length != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("cycle_length"), UINT2NUM(mesg->cycle_length));
	if(mesg->temperature != FIT_SINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("temperature"), INT2FIX(mesg->temperature));
	//rb_hash_aset(rh, rb_str_new2("compressed_speed_distance"), ///wtf);

	rb_funcall(cFitHandler, cFitHandlerRecordFun, 1, rh);
}

static pass_lap(const FIT_LAP_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->start_time != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_time"), UINT2NUM(mesg->start_time + GARMIN_SUCKS_OFFSET));
	if(mesg->start_position_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_position_lat"), fit_pos_to_rb(mesg->start_position_lat));
	if(mesg->start_position_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_position_long"), fit_pos_to_rb(mesg->start_position_long));
	if(mesg->end_position_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("end_position_lat"), fit_pos_to_rb(mesg->end_position_lat));
	if(mesg->end_position_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("end_position_long"), fit_pos_to_rb(mesg->end_position_long));
	if(mesg->total_elapsed_time != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_elapsed_time"), UINT2NUM(mesg->total_elapsed_time));
	if(mesg->total_timer_time != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_timer_time"), rb_float_new(mesg->total_timer_time / 1000.0));
	if(mesg->total_distance != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_distance"), rb_float_new(mesg->total_distance / 100.0));
	if(mesg->total_cycles != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_cycles"), UINT2NUM(mesg->total_cycles));
	if(mesg->nec_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("nec_lat"), fit_pos_to_rb(mesg->nec_lat));
	if(mesg->nec_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("nec_long"), fit_pos_to_rb(mesg->nec_long));
	if(mesg->swc_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("swc_lat"), fit_pos_to_rb(mesg->swc_lat));
	if(mesg->swc_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("swc_long"), fit_pos_to_rb(mesg->swc_long));
	if(mesg->message_index != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("message_index"), UINT2NUM(mesg->message_index));
	if(mesg->total_calories != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_calories"), UINT2NUM(mesg->total_calories));
	if(mesg->total_fat_calories != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_fat_calories"), UINT2NUM(mesg->total_fat_calories));
	if(mesg->avg_speed != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_speed"), rb_float_new(mesg->avg_speed / 1000.0));
	if(mesg->max_speed != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_speed"), rb_float_new(mesg->max_speed / 1000.0));
	if(mesg->avg_power != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_power"), UINT2NUM(mesg->avg_power));
	if(mesg->max_power != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_power"), UINT2NUM(mesg->max_power));
	if(mesg->total_ascent != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_ascent"), UINT2NUM(mesg->total_ascent));
	if(mesg->total_descent != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_descent"), UINT2NUM(mesg->total_descent));
//	if(mesg->event != FIT_UINT32_INVALID)
//		rb_hash_aset(rh, rb_str_new2("event"), UINT2NUM(mesg->event));
//	if(mesg->event_type != FIT_UINT32_INVALID)
//		rb_hash_aset(rh, rb_str_new2("event_type"), UINT2NUM(mesg->event_type));
	if(mesg->avg_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_heart_rate"), UINT2NUM(mesg->avg_heart_rate));
	if(mesg->max_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_heart_rate"), UINT2NUM(mesg->max_heart_rate));
	if(mesg->avg_cadence != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_cadence"), UINT2NUM(mesg->avg_cadence));
	if(mesg->max_cadence != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_cadence"), UINT2NUM(mesg->max_cadence));
//	if(mesg->intensity != FIT_UINT32_INVALID)
//		rb_hash_aset(rh, rb_str_new2("intensity"), mesg->intensity);
//		rb_hash_aset(rh, rb_str_new2("lap_trigger"), mesg->lap_trigger);
//		rb_hash_aset(rh, rb_str_new2("sport"), mesg->sport);
//		rb_hash_aset(rh, rb_str_new2("event_group"), mesg->event_group);

	rb_funcall(cFitHandler, cFitHandlerLapFun, 1, rh);
}

static pass_session(const FIT_SESSION_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->start_time != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_time"), UINT2NUM(mesg->start_time + GARMIN_SUCKS_OFFSET));
	if(mesg->start_position_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_position_lat"), fit_pos_to_rb(mesg->start_position_lat));
	if(mesg->start_position_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("start_position_long"), fit_pos_to_rb(mesg->start_position_long));
	if(mesg->total_elapsed_time != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_elapsed_time"), rb_float_new(mesg->total_elapsed_time / 1000.0));
	if(mesg->total_timer_time != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_timer_time"), rb_float_new(mesg->total_timer_time / 1000.0));
	if(mesg->total_distance != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_distance"), rb_float_new(mesg->total_distance / 100.0));
	if(mesg->total_cycles != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_cycles"), UINT2NUM(mesg->total_cycles));
	if(mesg->nec_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("nec_lat"), fit_pos_to_rb(mesg->nec_lat));
	if(mesg->nec_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("nec_long"), fit_pos_to_rb(mesg->nec_long));
	if(mesg->swc_lat != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("swc_lat"), fit_pos_to_rb(mesg->swc_lat));
	if(mesg->swc_long != FIT_SINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("swc_long"), fit_pos_to_rb(mesg->swc_long));
	if(mesg->message_index != FIT_MESSAGE_INDEX_INVALID)
		rb_hash_aset(rh, rb_str_new2("message_index"), UINT2NUM(mesg->message_index));
	if(mesg->total_calories != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_calories"), UINT2NUM(mesg->total_calories));
	//if(mesg->total_fat_calories != FIT_UINT16_INVALID)
	//	rb_hash_aset(rh, rb_str_new2("total_fat_calories"), UINT2NUM(mesg->total_fat_calories));
	if(mesg->avg_speed != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_speed"), rb_float_new(mesg->avg_speed / 1000.0));
	if(mesg->max_speed != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_speed"), rb_float_new(mesg->max_speed / 1000.0));
	if(mesg->avg_power != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_power"), UINT2NUM(mesg->avg_power));
	if(mesg->max_power != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_power"), UINT2NUM(mesg->max_power));
	if(mesg->total_ascent != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_ascent"), UINT2NUM(mesg->total_ascent));
	if(mesg->total_descent != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_descent"), UINT2NUM(mesg->total_descent));
	if(mesg->first_lap_index != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("first_lap_index"), UINT2NUM(mesg->first_lap_index));
	if(mesg->num_laps != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("num_laps"), UINT2NUM(mesg->num_laps));
	/*
	if(mesg->event != FIT_EVENT_INVALID)
		rb_hash_aset(rh, rb_str_new2("event"), UINT2NUM(mesg->event));
	if(mesg->event_type != FIT_EVENT_INVALID)
		rb_hash_aset(rh, rb_str_new2("event_type"), UINT2NUM(mesg->event_type));
	*/
	if(mesg->avg_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_heart_rate"), UINT2NUM(mesg->avg_heart_rate));
	if(mesg->max_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_heart_rate"), UINT2NUM(mesg->max_heart_rate));
	if(mesg->avg_cadence != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("avg_cadence"), UINT2NUM(mesg->avg_cadence));
	if(mesg->max_cadence != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("max_cadence"), UINT2NUM(mesg->max_cadence));
	if(mesg->sport != FIT_SPORT_INVALID)
		rb_hash_aset(rh, rb_str_new2("sport"), mesg->sport);
	if(mesg->sub_sport != FIT_SUB_SPORT_INVALID)
		rb_hash_aset(rh, rb_str_new2("sub_sport"), mesg->sub_sport);
	/*
	if(mesg->event_group != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("event_group"), mesg->event_group);
	if(mesg->total_training_effect != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("total_training_effect"), mesg->total_training_effect);
	*/

	rb_funcall(cFitHandler, cFitHandlerSessionFun, 1, rh);
}

static pass_user_profile(const FIT_USER_PROFILE_MESG *mesg) {
	VALUE rh = rb_hash_new();

	//rb_hash_aset(rh, rb_str_new2("friendly_name"), mesg->friendly_name);
	if(mesg->message_index != FIT_MESSAGE_INDEX_INVALID)
		rb_hash_aset(rh, rb_str_new2("message_index"), UINT2NUM(mesg->message_index));
	if(mesg->weight != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("weight"), rb_float_new(mesg->weight / 10.0));
	if(mesg->gender != FIT_GENDER_INVALID)
		rb_hash_aset(rh, rb_str_new2("gender"), UINT2NUM(mesg->gender));
	if(mesg->age != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("age"), UINT2NUM(mesg->age));
	if(mesg->height != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("height"), rb_float_new(mesg->height / 100.0));
	if(mesg->language != FIT_LANGUAGE_INVALID)
		rb_hash_aset(rh, rb_str_new2("language"), UINT2NUM(mesg->language));
	if(mesg->elev_setting != FIT_DISPLAY_MEASURE_INVALID)
		rb_hash_aset(rh, rb_str_new2("elev_setting"), UINT2NUM(mesg->elev_setting));
	if(mesg->weight_setting != FIT_DISPLAY_MEASURE_INVALID)
		rb_hash_aset(rh, rb_str_new2("weight_setting"), UINT2NUM(mesg->weight_setting));
	if(mesg->resting_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("resting_heart_rate"), UINT2NUM(mesg->resting_heart_rate));
	if(mesg->default_max_running_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("default_max_running_heart_rate"), UINT2NUM(mesg->default_max_running_heart_rate));
	if(mesg->default_max_biking_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("default_max_biking_heart_rate"), UINT2NUM(mesg->default_max_biking_heart_rate));
	if(mesg->default_max_heart_rate != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("default_max_heart_rate"), UINT2NUM(mesg->default_max_heart_rate));
	if(mesg->hr_setting != FIT_DISPLAY_HEART_INVALID)
		rb_hash_aset(rh, rb_str_new2("hr_setting"), UINT2NUM(mesg->hr_setting));
	if(mesg->speed_setting != FIT_DISPLAY_MEASURE_INVALID)
		rb_hash_aset(rh, rb_str_new2("speed_setting"), UINT2NUM(mesg->speed_setting));
	if(mesg->dist_setting != FIT_DISPLAY_MEASURE_INVALID)
		rb_hash_aset(rh, rb_str_new2("dist_setting"), UINT2NUM(mesg->dist_setting));
	if(mesg->power_setting != FIT_DISPLAY_POWER_INVALID)
		rb_hash_aset(rh, rb_str_new2("power_setting"), UINT2NUM(mesg->power_setting));
	if(mesg->activity_class != FIT_ACTIVITY_CLASS_INVALID)
		rb_hash_aset(rh, rb_str_new2("activity_class"), UINT2NUM(mesg->activity_class));
	if(mesg->position_setting != FIT_DISPLAY_POSITION_INVALID)
		rb_hash_aset(rh, rb_str_new2("position_setting"), UINT2NUM(mesg->position_setting));

	rb_funcall(cFitHandler, cFitHandlerUserProfileFun, 1, rh);
}

static pass_event(const FIT_EVENT_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	//rb_hash_aset(rh, rb_str_new2("data"), mesg->data);
	//rb_hash_aset(rh, rb_str_new2("data16"), mesg->data16);
	//rb_hash_aset(rh, rb_str_new2("event"), mesg->event);
	if(mesg->timestamp != FIT_UINT32_INVALID)
		rb_hash_aset(rh, rb_str_new2("event_type"), UINT2NUM(mesg->event_type));
	//rb_hash_aset(rh, rb_str_new2("event_group"), mesg->event_group);

	rb_funcall(cFitHandler, cFitHandlerEventFun, 1, rh);
}

static pass_device_info(const FIT_DEVICE_INFO_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->serial_number != FIT_UINT32Z_INVALID)
		rb_hash_aset(rh, rb_str_new2("serial_number"), UINT2NUM(mesg->serial_number));
	if(mesg->manufacturer != FIT_MANUFACTURER_INVALID)
		rb_hash_aset(rh, rb_str_new2("manufacturer"), UINT2NUM(mesg->manufacturer));
	if(mesg->product != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("product"), UINT2NUM(mesg->product));
	if(mesg->software_version != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("software_version"), UINT2NUM(mesg->software_version));
	if(mesg->battery_voltage != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("battery_voltage"), UINT2NUM(mesg->battery_voltage));
	if(mesg->device_index != FIT_DEVICE_INDEX_INVALID)
		rb_hash_aset(rh, rb_str_new2("device_index"), UINT2NUM(mesg->device_index));
	if(mesg->device_type != FIT_DEVICE_TYPE_INVALID)
		rb_hash_aset(rh, rb_str_new2("device_type"), UINT2NUM(mesg->device_type));
	if(mesg->hardware_version != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("hardware_version"), UINT2NUM(mesg->hardware_version));
	if(mesg->battery_status != FIT_BATTERY_STATUS_INVALID)
		rb_hash_aset(rh, rb_str_new2("battery_status"), UINT2NUM(mesg->battery_status));

	rb_funcall(cFitHandler, cFitHandlerDeviceInfoFun, 1, rh);
}

static pass_weight_scale_info(const FIT_WEIGHT_SCALE_MESG *mesg) {
	VALUE rh = rb_hash_new();

	if(mesg->timestamp != FIT_DATE_TIME_INVALID)
		rb_hash_aset(rh, rb_str_new2("timestamp"), UINT2NUM(mesg->timestamp + GARMIN_SUCKS_OFFSET));
	if(mesg->weight != FIT_WEIGHT_INVALID)
		rb_hash_aset(rh, rb_str_new2("weight"), rb_float_new(mesg->weight / 100.0));
	if(mesg->percent_fat != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("percent_fat"), rb_float_new(mesg->percent_fat / 100.0));
	if(mesg->percent_hydration != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("percent_hydration"), rb_float_new(mesg->percent_hydration / 100.0));
	if(mesg->visceral_fat_mass != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("visceral_fat_mass"), rb_float_new(mesg->visceral_fat_mass / 100.0));
	if(mesg->bone_mass != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("bone_mass"), rb_float_new(mesg->bone_mass / 100.0));
	if(mesg->muscle_mass != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("muscle_mass"), rb_float_new(mesg->muscle_mass / 100.0));
	if(mesg->basal_met != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("basal_met"), rb_float_new(mesg->basal_met / 4.0));
	if(mesg->active_met != FIT_UINT16_INVALID)
		rb_hash_aset(rh, rb_str_new2("active_met"), rb_float_new(mesg->active_met / 4.0));
	if(mesg->physique_rating != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("physique_rating"), rb_float_new(mesg->physique_rating));
	if(mesg->metabolic_age != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("metabolic_age"), rb_float_new(mesg->metabolic_age));
	if(mesg->visceral_fat_rating != FIT_UINT8_INVALID)
		rb_hash_aset(rh, rb_str_new2("visceral_fat_rating"), rb_float_new(mesg->visceral_fat_rating));

	rb_funcall(cFitHandler, cFitHandlerWeightScaleInfoFun, 1, rh);
}

static VALUE parse(VALUE self, VALUE original_str) {
	int i = 0;
	VALUE str = StringValue(original_str);
	char *p = RSTRING_PTR(str);
	char err_msg[128];
	
	FIT_UINT8 buf[8];
	FIT_CONVERT_RETURN convert_return = FIT_CONVERT_CONTINUE;
	FIT_UINT32 buf_size;
	FIT_UINT32 mesg_index = 0;
#if defined(FIT_CONVERT_MULTI_THREAD)
	FIT_CONVERT_STATE state;
#endif

#if defined(FIT_CONVERT_MULTI_THREAD)
	FitConvert_Init(&state, FIT_TRUE);
#else
	FitConvert_Init(FIT_TRUE);
#endif

	if(RSTRING_LEN(str) == 0) {
		//sprintf(err_msg, "Passed in string with length of 0!");
		pass_message(err_msg);
		return Qnil;
	}

	while(i < RSTRING_LEN(str) && (convert_return == FIT_CONVERT_CONTINUE)) {
		for(buf_size=0;(buf_size < sizeof(buf)) && (p != NULL); buf_size++) {
			buf[buf_size] = *p;
			p++;
			i++;
		}

		do {
#if defined(FIT_CONVERT_MULTI_THREAD)
			convert_return = FitConvert_Read(&state, buf, buf_size);
#else
			convert_return = FitConvert_Read(buf, buf_size);
#endif

			switch(convert_return) {
				case FIT_CONVERT_MESSAGE_AVAILABLE: {
#if defined(FIT_CONVERT_MULTI_THREAD)
					const FIT_UINT8 *mesg = FitConvert_GetMessageData(&state);
					FIT_UINT16 mesg_num = FitConvert_GetMessageNumber(&state);
#else
					const FIT_UINT8 *mesg = FitConvert_GetMessageData();
					FIT_UINT16 mesg_num = FitConvert_GetMessageNumber();
#endif

					//sprintf(err_msg, "Mesg %d (%d) - ", mesg_index++, mesg_num);
					//pass_message(err_msg);

					switch(mesg_num) {
						case FIT_MESG_NUM_FILE_ID: {
							const FIT_FILE_ID_MESG *id = (FIT_FILE_ID_MESG *) mesg;
							//sprintf(err_msg, "File ID: type=%u, number=%u\n", id->type, id->number);
							//pass_message(err_msg);
							break;
						}

						case FIT_MESG_NUM_USER_PROFILE: {
							const FIT_USER_PROFILE_MESG *user_profile = (FIT_USER_PROFILE_MESG *) mesg;
							//sprintf(err_msg, "User Profile: weight=%0.1fkg\n", user_profile->weight / 10.0f); 
							//pass_message(err_msg);
							pass_user_profile(user_profile);
							break;
						}

						case FIT_MESG_NUM_ACTIVITY: {
							const FIT_ACTIVITY_MESG *activity = (FIT_ACTIVITY_MESG *) mesg;
							//sprintf(err_msg, "Activity: timestamp=%u, type=%u, event=%u, event_type=%u, num_sessions=%u\n", activity->timestamp, activity->type, activity->event, activity->event_type, activity->num_sessions); 
							//pass_message(err_msg);
							pass_activity(activity);

							{
								FIT_ACTIVITY_MESG old_mesg;
								old_mesg.num_sessions = 1;
#if defined(FIT_CONVERT_MULTI_THREAD)
								FitConvert_RestoreFields(&state, &old_mesg);
#else
								FitConvert_RestoreFields(&old_mesg);
#endif
								//sprintf(err_msg, "Restored num_sessions=1 - Activity: timestamp=%u, type=%u, event=%u, event_type=%u, num_sessions=%u\n", activity->timestamp, activity->type, activity->event, activity->event_type, activity->num_sessions); 
								//pass_message(err_msg);
							}
							break;
						}

						case FIT_MESG_NUM_SESSION: {
							const FIT_SESSION_MESG *session = (FIT_SESSION_MESG *) mesg;
							//sprintf(err_msg, "Session: timestamp=%u\n", session->timestamp); 
							//pass_message(err_msg);
							pass_session(session);
							break;
						}

						case FIT_MESG_NUM_LAP: {
							const FIT_LAP_MESG *lap = (FIT_LAP_MESG *) mesg;
							//sprintf(err_msg, "Lap: timestamp=%u, total_ascent=%u, total_distance=%f\n", lap->timestamp, lap->total_ascent, (lap->total_distance / 100.0) / 1000.0 * 0.621371192);
							//pass_message(err_msg);
							pass_lap(lap);
							break;
						}

						case FIT_MESG_NUM_RECORD: {
							const FIT_RECORD_MESG *record = (FIT_RECORD_MESG *) mesg;

							//sprintf(err_msg, "Record: timestamp=%u", record->timestamp);
							//pass_message(err_msg);
							pass_record(record);
							break;
						}

						case FIT_MESG_NUM_EVENT: {
							const FIT_EVENT_MESG *event = (FIT_EVENT_MESG *) mesg;
							//sprintf(err_msg, "Event: timestamp=%u, event_type = %i\n", event->timestamp, event->event_type); 
							//pass_message(err_msg);
							pass_event(event);
							break;
						}

						case FIT_MESG_NUM_DEVICE_INFO: {
							const FIT_DEVICE_INFO_MESG *device_info = (FIT_DEVICE_INFO_MESG *) mesg;
							//sprintf(err_msg, "Device Info: timestamp=%u, battery_status=%u\n", (unsigned int)device_info->timestamp, device_info->battery_voltage);
							//pass_message(err_msg);
							pass_device_info(device_info);
							break;
						}

						case FIT_MESG_NUM_WEIGHT_SCALE: {
							const FIT_WEIGHT_SCALE_MESG *weight_scale_info = (FIT_WEIGHT_SCALE_MESG *) mesg;
							//sprintf(err_msg, "Device Info: timestamp=%u, battery_status=%u\n", (unsigned int)device_info->timestamp, device_info->battery_voltage);
							//pass_message(err_msg);
							pass_weight_scale_info(weight_scale_info);
							break;
						}

						default: {
							//sprintf(err_msg, "Unknown\n");
							//pass_message(err_msg);
							break;
						}
					}
					break;
				}
				default:
					break;
			}
		} while (convert_return == FIT_CONVERT_MESSAGE_AVAILABLE);
	}

	if (convert_return == FIT_CONVERT_ERROR) {
		//sprintf(err_msg, "Error decoding file.\n");
		pass_message(err_msg);
		//fclose(file);
		return Qnil;
	}

	if (convert_return == FIT_CONVERT_CONTINUE) {
		//sprintf(err_msg, "Unexpected end of file.\n");
		//pass_message(err_msg);
		//fclose(file);
		//return Qnil;
	}

	if (convert_return == FIT_CONVERT_PROTOCOL_VERSION_NOT_SUPPORTED) {
		//sprintf(err_msg, "Protocol version not supported.\n");
		pass_message(err_msg);
		//fclose(file);
		return Qnil;
	}

	if (convert_return == FIT_CONVERT_END_OF_FILE) {
		//sprintf(err_msg, "File converted successfully.\n");
		pass_message(err_msg);
	}

	return Qnil;
}

void Init_fit_parser() {
	cFitParser = rb_define_class("FitParser", rb_cObject);

	//instance methods
	rb_define_method(cFitParser, "initialize", init, 1);
	rb_define_method(cFitParser, "parse", parse, 1);

	//attributes
	HANDLER_ATTR = rb_intern("@handler");
	rb_define_attr(cFitParser, "handler", 1, 1);
}
