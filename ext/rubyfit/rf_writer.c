
#define _CRT_SECURE_NO_WARNINGS

#include "rf_writer.h"

#include "stdio.h"
#include "string.h"

#include "fit_example.h"
#include "fit_crc.h"

ID WHANDLER_ATTR;

VALUE cFitWHandlerPrintFun;
VALUE cFitWHandlerPrintErrFun;
VALUE cFitWHandlerDataFun;

struct rf_writer_data {
    FIT_UINT16 data_crc;
    FILE *fp;
};

//static const rb_data_type_t rf_writer_data_type = {
//        "fit",
//        {0, free_file, memsize_file,},
//        0, 0,
//        RUBY_TYPED_FREE_IMMEDIATELY,
//};

static struct rf_writer_data *w_data;

static void writeData(VALUE self, const void *data, FIT_UINT8 data_size) {

    fwrite(data, 1, data_size, w_data->fp);

    FIT_UINT8 offset;

    for (offset = 0; offset < data_size; offset++)
        w_data->data_crc = FitCRC_Get16(w_data->data_crc, *((FIT_UINT8 *) data + offset));
}

// TODO size D:
static void writeHeader(VALUE self) {
    FIT_FILE_HDR file_header;

    file_header.header_size = FIT_FILE_HDR_SIZE;
    file_header.profile_version = FIT_PROFILE_VERSION;
    file_header.protocol_version = FIT_PROTOCOL_VERSION_20;
    memcpy((FIT_UINT8 *) &file_header.data_type, ".FIT", 4);
    fseek(w_data->fp, 0, SEEK_END);
    file_header.data_size = ftell(w_data->fp) - FIT_FILE_HDR_SIZE - sizeof(FIT_UINT16);
    file_header.crc = FitCRC_Calc16(&file_header, FIT_STRUCT_OFFSET(crc, FIT_FILE_HDR));

    fseek(w_data->fp, 0, SEEK_SET);
    fwrite((void *) &file_header, 1, FIT_FILE_HDR_SIZE, w_data->fp);
}

static void writeMessageDefinition(VALUE self, FIT_UINT8 local_mesg_number, const void *mesg_def_pointer, FIT_UINT8 mesg_def_size) {
    FIT_UINT8 header = local_mesg_number | FIT_HDR_TYPE_DEF_BIT;
    writeData(self, &header, FIT_HDR_SIZE);
    writeData(self, mesg_def_pointer, mesg_def_size);
}

static void writeMessageDefinitionWithDevFields
        (
                VALUE self,
                FIT_UINT8 local_mesg_number,
                const void *mesg_def_pointer,
                FIT_UINT8 mesg_def_size,
                FIT_UINT8 number_dev_fields,
                FIT_DEV_FIELD_DEF *dev_field_definitions,
                FILE *fp
        ) {
    FIT_UINT16 i;
    FIT_UINT8 header = local_mesg_number | FIT_HDR_TYPE_DEF_BIT | FIT_HDR_DEV_DATA_BIT;
    writeData(self, &header, FIT_HDR_SIZE);
    writeData(self, mesg_def_pointer, mesg_def_size);

    writeData(self, &number_dev_fields, sizeof(FIT_UINT8));
    for (i = 0; i < number_dev_fields; i++) {
        writeData(self, &dev_field_definitions[i], sizeof(FIT_DEV_FIELD_DEF));
    }
}

static void writeMessage(VALUE self, FIT_UINT8 local_mesg_number, const void *mesg_pointer, FIT_UINT8 mesg_size) {
    writeData(self, &local_mesg_number, FIT_HDR_SIZE);
    writeData(self, mesg_pointer, mesg_size);
}

static void writeFileId(VALUE self) {
    FIT_UINT8 local_mesg_number = 0;
    FIT_FILE_ID_MESG file_id;
    Fit_InitMesg(fit_mesg_defs[FIT_MESG_FILE_ID], &file_id);
    file_id.type = FIT_FILE_SETTINGS;
    file_id.manufacturer = FIT_MANUFACTURER_GARMIN;
    writeMessageDefinition(self, local_mesg_number, fit_mesg_defs[FIT_MESG_FILE_ID], FIT_FILE_ID_MESG_DEF_SIZE);
    writeMessage(self, local_mesg_number, &file_id, FIT_FILE_ID_MESG_SIZE);
}

static void writeDeveloperId(VALUE self) {
    const FIT_UINT8 appId[] =
            {
                    0x0, 0x1, 0x2, 0x3,
                    0x4, 0x5, 0x6, 0x7,
                    0x8, 0x9, 0xA, 0xB,
                    0xC, 0xD, 0xE, 0xF
            };
    FIT_UINT8 local_mesg_number = 0;
    FIT_DEVELOPER_DATA_ID_MESG data_id_mesg;
    Fit_InitMesg(fit_mesg_defs[FIT_MESG_DEVELOPER_DATA_ID], &data_id_mesg);
    data_id_mesg.developer_data_index = 0;
    memcpy(data_id_mesg.application_id, appId, FIT_DEVELOPER_DATA_ID_MESG_APPLICATION_ID_COUNT);
    data_id_mesg.manufacturer_id = FIT_MANUFACTURER_GARMIN;

    writeMessageDefinition(self, local_mesg_number, fit_mesg_defs[FIT_MESG_DEVELOPER_DATA_ID],
                           FIT_DEVELOPER_DATA_ID_MESG_DEF_SIZE);
    writeMessage(self, local_mesg_number, &data_id_mesg, FIT_DEVELOPER_DATA_ID_MESG_SIZE);
}

static VALUE rf_w_init(VALUE self, VALUE handler) {
    rb_ivar_set(self, WHANDLER_ATTR, handler);

    w_data = malloc(sizeof(w_data));

    // Allocate and attach our data to the ruby object?
//    obj = TypedData_Make_Struct(klass, struct rf_writer_data, &rf_writer_data_type, w_data);
//    data_crc = 0;

    writeHeader(self);
    writeFileId(self);

    return Qnil;
}

static VALUE rf_w_close(VALUE self) {

    // Write CRC.
    fwrite(&w_data->data_crc, 1, sizeof(FIT_UINT16), w_data->fp);

    // Update file header with data size.
    writeHeader(self);

    return Qnil;
}

void rf_writer_define(VALUE cFitWriter) {
    rb_define_method(cFitWriter, "initialize", rf_w_init, 1);

    //attributes
    rb_define_attr(cFitWriter, "handler", 1, 1);
    WHANDLER_ATTR = rb_intern("@handler");

    cFitWHandlerPrintFun = rb_intern("print_msg");
    cFitWHandlerPrintErrFun = rb_intern("print_error_msg");
    cFitWHandlerDataFun = rb_intern("on_data");

}
