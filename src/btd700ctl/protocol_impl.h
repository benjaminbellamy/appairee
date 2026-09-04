#ifndef BTD700_PROTOCOL_IMPL_H
#define BTD700_PROTOCOL_IMPL_H

/* ========================================================================== */
/* device identifiers                                                         */
/* ========================================================================== */

#define BTD700_VENDOR_ID    0x3542
#define BTD700_PID          0x3001
#define BTD700_USAGE_PAGE   0xFFA2
#define BTD700_USAGE        0x01
#define BTD700_REPORT_ID    0x34

/* ========================================================================== */
/* packet markers                                                             */
/* ========================================================================== */

#define BTD700_MARKER_DONGLE_CMD  0xFC   /* dongle -> host (unsolicited) */
#define BTD700_MARKER_HOST_RSP    0xFD   /* host -> dongle (ack)         */
#define BTD700_MARKER_HOST_CMD    0xFE   /* host -> dongle (command)     */
#define BTD700_MARKER_DONGLE_RSP  0xFF   /* dongle -> host (response)    */

/* ========================================================================== */
/* host -> dongle command IDs                                                 */
/* ========================================================================== */

#define CMD_GET_AUDIO_MODE          0x01
#define CMD_SET_AUDIO_MODE          0x02
#define CMD_GET_SUPPORTED_CODEC     0x03
#define CMD_SET_CODEC               0x04
#define CMD_GET_CODEC_IN_USE        0x05
#define CMD_GET_DONGLE_STATE        0x06
#define CMD_GET_LE_AUDIO_STATE      0x07
#define CMD_GET_AUDIO_QUALITY       0x08
#define CMD_GET_BROADCAST_INFO      0x09
#define CMD_SET_BROADCAST_INFO      0x0A
#define CMD_GET_BROADCAST_KEY       0x0B
#define CMD_SET_BROADCAST_KEY       0x0C
#define CMD_GET_BROADCAST_NAME      0x0D
#define CMD_SET_BROADCAST_NAME      0x0E
#define CMD_GET_FIRMWARE_VERSION    0x12
#define CMD_SET_FACTORY_RESET       0x13
#define CMD_SET_BT_CONNECT          0x14
#define CMD_GET_SINK_TRANSPORT      0x15
#define CMD_GET_GAMING_STATUS       0x17

/* ========================================================================== */
/* dongle -> host event IDs                                                   */
/* ========================================================================== */

#define EVT_AUDIO_MODE              0x02
#define EVT_SUPPORTED_CODEC         0x03
#define EVT_CODEC_TO_USE            0x04
#define EVT_DONGLE_STATE            0x0F
#define EVT_LE_AUDIO_STATE          0x10
#define EVT_AUDIO_QUALITY           0x11
#define EVT_SINK_TRANSPORT          0x16
#define EVT_GAMING_STATUS           0x17

#endif /* BTD700_PROTOCOL_IMPL_H */
