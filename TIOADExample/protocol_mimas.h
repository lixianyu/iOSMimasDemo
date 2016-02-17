//
//  protocol_mimas.h
//  iOSMimas
//
//  Created by Li Xianyu on 16/2/15.
//  Copyright © 2016年 Texas Instruments. All rights reserved.
//

#ifndef protocol_mimas_h
#define protocol_mimas_h

#include <stdio.h>
#include <stdint.h>
#if 0
#include <_types/_uint16_t.h>
#include <_types/_uint8_t.h>
#include <_types/_uint32_t.h>
#endif
#define GLOBAL_RESPONSE_BUFFER_SIZE 200

typedef enum {
    SEND_SUCCESS = 1,
    SEND_FAIL = 0,
}SEND_STATUS;

typedef enum {
    WAIT_START = 0,
    WAIT_MESSAGE,
    MESSAGE_RESOLVE
}RECEIVE_STATE;

/* Command ID */
typedef enum {
    FIRMWARE_UPDATE_CMD_ID = 0x01,
    SET_CONFIG_COMMAND_ID = 0x02,
    BOND_COMMAND_ID = 0x03,
    NOTIFY_COMMAND_ID = 0x04,
    HEALTH_DATA_COMMAND_ID = 0x05,
    FACTORY_TEST_COMMAND_ID = 0x06,
    BLUETOOTH_LOG_COMMAND_ID = 0x0a,
    GET_STACK_DUMP          = 0x10,
    TEST_FLASH_READ_WRITE = 0xFE,
    TEST_COMMAND_ID = 0xFF
}BLUETOOTH_COMMUNICATE_COMMAND;

#define BLE_NUS_MAX_DATA_LEN 20

#define L1_HEADER_MAGIC  (0xAB)     /*header magic number */
#define L1_HEADER_VERSION (0x00)     /*protocol version */
#define L1_HEADER_SIZE   (8)      /*L1 header length*/

/**************************************************************************
 * define L1 header byte order
 ***************************************************************************/
#define L1_HEADER_MAGIC_POS             (0)
#define L1_HEADER_PROTOCOL_VERSION_POS  (1)
#define L1_PAYLOAD_LENGTH_HIGH_BYTE_POS (2)         /* L1 payload length high byte */
#define L1_PAYLOAD_LENGTH_LOW_BYTE_POS  (3)
#define L1_HEADER_CRC16_HIGH_BYTE_POS   (4)
#define L1_HEADER_CRC16_LOW_BYTE_POS    (5)
#define L1_HEADER_SEQ_ID_HIGH_BYTE_POS  (6)
#define L1_HEADER_SEQ_ID_LOW_BYTE_POS   (7)

/********************************************************************************
 * define version response
 *********************************************************************************/
typedef enum {
    DATA_PACKAGE = 0,
    RESPONSE_PACKAGE =  1,
}L1_PACKAGE_TYPE;

/********************************************************************************
 * define ack or nak
 *********************************************************************************/
typedef enum {
    ACK = 0,
    NAK = 1,
}L1_ERROR_FLAG;

/*******************************************************************************
 * debvice loss alert level
 ********************************************************************************/
typedef enum {
    NO_ALERT = 0,
    MIDDLE_ALERT = 1,
    HIGH_ALERT = 2
} DEV_LOSS_ALERT_LEVEL;

#define L2_HEADER_SIZE   (2)      /*L2 header length*/
#define L2_HEADER_VERSION (0x00)     /*L2 header version*/
#define L2_KEY_SIZE         (1)
#define L2_PAYLOAD_HEADER_SIZE (3)        /*L2 payload header*/

#define L2_FIRST_VALUE_POS (L2_HEADER_SIZE + L2_PAYLOAD_HEADER_SIZE)
/*****************************************/
#define L1L2_HEAD_LEN  (5)

#define SPORT_HEAD_LEN (L1L2_HEAD_LEN+4)

#define SPOTSMODE_POS (12)
/*****************************************/

/*********************************************************************
 * individual response buffer
 **********************************************************************/
struct Response_Buff_Type_t
{
    uint16_t sequence_id;
    uint8_t  check_success;
    uint8_t  isUsed;
};

#define MAX_SEND_TASK  (1)      /* for only one buffer */

#define SEND_RETRY_TIMES (10)    /*send retry timers*/

/* L1 header struct */
typedef struct
{
    uint8_t magic;
    uint8_t version;
    uint16_t payload_len;
    uint16_t crc16;
    uint16_t sequence_id;
}
L1Header_t;

/*L1 version defination */
typedef struct
{
    uint8_t version  :
    4;
    uint8_t ack_flag  :
    1;
    uint8_t err_flag  :
    1;
    uint8_t reserve  :
    2;
}
L1_version_def_t;

typedef union{
    L1_version_def_t version_def;
    uint8_t value;
}L1_version_value_t;

enum crc_check_result
{
    CRC_SUCCESS = 0,
    CRC_FAIL = 1
};

typedef struct
{
    uint8_t should_alert;              /* control should alert or not */
    uint8_t alert_level;
}
dev_loss_control_t;

typedef union {
    uint16_t data;
    dev_loss_control_t controller;
}dev_loss_control;

typedef struct
{
    uint16_t v_length  :
    9;
    uint16_t reserve  :
    7;
}
Key_Header_t;
typedef union
{
    uint16_t data;
    Key_Header_t key_header_bit_field;
} Key_Header_u;

typedef struct
{
    uint8_t cmd_ID;
    uint8_t version;
    uint8_t key;
    Key_Header_u key_header;
}
L2DataHeader_t;

typedef enum  {
    KEY_REQUEST_DATA   = 0x01,
    KEY_RETURN_SPORTS_DATA  = 0x02,
    KEY_RETURN_SLEEP_DATA  = 0x03,
    KEY_MORE    = 0x04,
    KEY_RETURN_SLEEP_SETTING= 0x05,
    KEY_SET_STEPS_NOTIFY =0x06,
    KEY_DATA_SYNC_START= 0x07,
    KEY_DATA_SYNC_END =0x08,
    KEY_DAILY_DATA_SYNC = 0x09,
    KEY_LATEST_DATA_SYNC = 0x0A
    
}SPORTS_KEY;
typedef enum  {
    KEY_TIME_SETTINGS   = 0x01,
    KEY_ALARM_SETTINGS  = 0x02,
    KEY_REQUEST_ALARM_SETTINGS  = 0x03,
    KEY_RETURN_ALARM_SETTINGS = 0x04,
    KEY_STEP_TARGET_SETTINGS = 0x05,
    KEY_PROFILE_SETTINGS = 0x10,
    KEY_DEV_LOSS_ALERT_SETTINGS = 0x20
}SETTINGS_KEY;

typedef enum {
    KEY_REQUEST_ECHO    = 0x01,
    KEY_RETURN_ECHO     = 0x02,
    KEY_REQUEST_CHARGE  = 0x03,
    KEY_RETURN_CHARGE   = 0x04,
    KEY_LED_TEST        = 0x05,
    KEY_VIBRATOR_TEST   = 0x06,
    KEY_WRITE_SN        = 0x07,
    KEY_READ_SN         = 0x08,
    KEY_RETURN_SN       = 0x09,
    KEY_WRITE_FLAG      = 0x0a,
    KEY_READ_FLAG       = 0x0b,
    KEY_RETURN_FLAG     = 0x0c,
    KEY_REQUEST_SENSOR  = 0x0d,
    KEY_RETURN_SENSOR   = 0x0e,
    KEY_ENTER_TEST_MODE = 0x10,
    KEY_EXIT_TEST_MODE  = 0x11,
}FACTORY_TEST_KEY;

typedef enum {
    KEY_ENTER_FIRMWARE_UPDATE_MODE  = 0x01,
    KEY_ENTER_DFU_MODE_RET          = 0x02,
    KEY_GET_FIRMWARE_VERSION_INFO   = 0x11,
    KEY_RET_FIRMWARE_VERSION_INFO   = 0x12,
}FIRMWARE_UPDATE_KEY;

typedef enum {
    DO_BOND = 0,
    DO_WAIT_BOND_COMMAND = 1
}USER_TIMER_COMMAND_t;


typedef enum{
    PRIVATE_NOT_BOND = 0,
    PRIVATE_BOND_SUCCESS = 1
} BLUETOOTH_BOND_STATE;


//async send operation callback
typedef void (*send_status_callback_t)(SEND_STATUS status );

typedef struct
{
    uint8_t *         content;   /* content to be send */
    send_status_callback_t   callback;   /* send status callback */
    uint16_t          length;    /* content length */
}
L2_Send_Content;

/*Used by L1, used to send whole L1 package throw bluetooth */
typedef struct
{
    uint8_t *         content;   /* content to be send */
    send_status_callback_t                   callback;   /* send status callback */
    uint16_t        length;    /* content length */
    uint16_t        contentLeft;     /* content left for send*/
    uint16_t         sequence_id;        /* sequence id for this package*/
    uint8_t         isUsed;    /* is the current struct used*/
    uint8_t         resendCount;     /* whole L1 package resend count */
}
L1_Send_Content;

typedef enum {
    CONTENT_NONE = 0,
    CONTENT_HEADER = 1,
    CONTENT_DATA = 2,
    CONTENT_ACK = 3
}SEND_CONTENT_TYPE_T;

/****************************************************************
 * sending Buffer use state
 *****************************************************************/
typedef struct
{
    uint8_t isUsed      :
    1;
    uint8_t TxComplete  :
    1;
    uint8_t GetResPack  :
    1;
    uint8_t reserved    :
    5;
}
SendingBufferUseState_t;

typedef union {
    uint8_t data;
    SendingBufferUseState_t usingState;
}SendingBufferUseState;

/***********************************************************************
 * This enum describe the current task type
 ************************************************************************/
typedef enum {
    TASK_NONE = 0,
    TASK_DATA = 1,
    TASK_ACK = 2
}SEND_TASK_TYPE_T;

typedef struct
{
    L1_Send_Content * content;
    uint16_t        isUsed;
}
L1_Header_Schedule_type_t;

/* time bit field */
typedef struct
{
    uint32_t seconds  :
    6;
    uint32_t minute  :
    6;
    uint32_t hours  :
    5;
    uint32_t day   :
    5;
    uint32_t month  :
    4;
    uint32_t year   :
    6;
}
time_bit_field_type_t;

typedef union
{
    uint32_t data;
    time_bit_field_type_t time;
} time_union_t;
/* time bit field */

/* Definend for send callback */
typedef void (*send_complete_callback_t)(void *context,SEND_TASK_TYPE_T type);

typedef  struct
{
    send_complete_callback_t callback;
    void * context;
    SEND_TASK_TYPE_T task_type;
}
SendCompletePara;


/* log command and key */
typedef enum {
    KEY_ENABLE_BLUETOOTH_LOG    = 0x01,
    KEY_DISABLE_BLUETOOTH_LOG   = 0x02,
    KEY_BLUETOOTH_LOG_CONTENT   = 0x03,
}log_command_key_t;

/////////////////////////////////////////
#define NRF_ERROR_BASE_NUM      (0x0)       ///< Global error base
#define NRF_ERROR_SDM_BASE_NUM  (0x1000)    ///< SDM error base
#define NRF_ERROR_SOC_BASE_NUM  (0x2000)    ///< SoC error base
#define NRF_ERROR_STK_BASE_NUM  (0x3000)    ///< STK error base
/** @} */

#define NRF_SUCCESS                           (NRF_ERROR_BASE_NUM + 0)  ///< Successful command
#define NRF_ERROR_SVC_HANDLER_MISSING         (NRF_ERROR_BASE_NUM + 1)  ///< SVC handler is missing
#define NRF_ERROR_SOFTDEVICE_NOT_ENABLED      (NRF_ERROR_BASE_NUM + 2)  ///< SoftDevice has not been enabled
#define NRF_ERROR_INTERNAL                    (NRF_ERROR_BASE_NUM + 3)  ///< Internal Error
#define NRF_ERROR_NO_MEM                      (NRF_ERROR_BASE_NUM + 4)  ///< No Memory for operation
#define NRF_ERROR_NOT_FOUND                   (NRF_ERROR_BASE_NUM + 5)  ///< Not found
#define NRF_ERROR_NOT_SUPPORTED               (NRF_ERROR_BASE_NUM + 6)  ///< Not supported
#define NRF_ERROR_INVALID_PARAM               (NRF_ERROR_BASE_NUM + 7)  ///< Invalid Parameter
#define NRF_ERROR_INVALID_STATE               (NRF_ERROR_BASE_NUM + 8)  ///< Invalid state, operation disallowed in this state
#define NRF_ERROR_INVALID_LENGTH              (NRF_ERROR_BASE_NUM + 9)  ///< Invalid Length
#define NRF_ERROR_INVALID_FLAGS               (NRF_ERROR_BASE_NUM + 10) ///< Invalid Flags
#define NRF_ERROR_INVALID_DATA                (NRF_ERROR_BASE_NUM + 11) ///< Invalid Data
#define NRF_ERROR_DATA_SIZE                   (NRF_ERROR_BASE_NUM + 12) ///< Data size exceeds limit
#define NRF_ERROR_TIMEOUT                     (NRF_ERROR_BASE_NUM + 13) ///< Operation timed out
#define NRF_ERROR_NULL                        (NRF_ERROR_BASE_NUM + 14) ///< Null Pointer
#define NRF_ERROR_FORBIDDEN                   (NRF_ERROR_BASE_NUM + 15) ///< Forbidden Operation
#define NRF_ERROR_INVALID_ADDR                (NRF_ERROR_BASE_NUM + 16) ///< Bad Memory Address
#define NRF_ERROR_BUSY                        (NRF_ERROR_BASE_NUM + 17) ///< Busy


extern void generate_l2_package(
                                L2_Send_Content *content,
                                BLUETOOTH_COMMUNICATE_COMMAND id,
                                uint8_t key,
                                uint16_t length,
                                uint8_t* value);
extern void generate_l1_package(L2_Send_Content *l2_content, L1_Send_Content *l1_content);

#endif /* protocol_mimas_h */
