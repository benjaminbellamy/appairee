#ifndef BTD700_C_H
#define BTD700_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
    #ifdef BTD700_BUILDING
        #define BTD700_API __declspec(dllexport)
    #else
        #define BTD700_API __declspec(dllimport)
    #endif
#elif defined(__GNUC__) || defined(__clang__)
    #define BTD700_API __attribute__((visibility("default")))
#else
    #define BTD700_API
#endif

typedef enum {
    BTD700_OK                   =  0,
    BTD700_ERR_DEVICE_NOT_FOUND = -1,
    BTD700_ERR_DEVICE_NOT_OPEN  = -2,
    BTD700_ERR_HID              = -3,
    BTD700_ERR_INVALID_ARG      = -4,
} btd700_error_t;

typedef enum {
    BTD700_AUDIO_MODE_HIGH_QUALITY = 0,
    BTD700_AUDIO_MODE_GAMING       = 1,
    BTD700_AUDIO_MODE_BROADCAST    = 2,
} btd700_audio_mode_t;

typedef enum {
    BTD700_TRANSPORT_DISCONNECTED = 0,
    BTD700_TRANSPORT_CLASSIC      = 1,
    BTD700_TRANSPORT_LE_AUDIO     = 2,
    BTD700_TRANSPORT_MULTIPOINT   = 3,
} btd700_transport_mode_t;

typedef enum {
    BTD700_FREQ_44100 = 1,
    BTD700_FREQ_48000 = 2,
    BTD700_FREQ_96000 = 3,
} btd700_audio_frequency_t;

typedef enum {
    BTD700_RES_16BIT = 1,
    BTD700_RES_24BIT = 2,
} btd700_audio_resolution_t;

typedef enum {
    BTD700_CODEC_SBC           = 0,
    BTD700_CODEC_APTX          = 1,
    BTD700_CODEC_APTX_ADAPTIVE = 2,
    BTD700_CODEC_APTX_LOSSLESS = 3,
    BTD700_CODEC_APTX_LITE     = 4,
    BTD700_CODEC_LC3           = 5,
} btd700_codec_t;

#define BTD700_CODEC_MASK_SBC              (1 << 0)
#define BTD700_CODEC_MASK_APTX             (1 << 1)
#define BTD700_CODEC_MASK_APTX_ADAPTIVE    (1 << 2)
#define BTD700_CODEC_MASK_APTX_LOSSLESS    (1 << 3)
#define BTD700_CODEC_MASK_APTX_LITE        (1 << 4)
#define BTD700_CODEC_MASK_LC3              (1 << 5)
#define BTD700_CODEC_MASK_ALL              0x3F

typedef enum {
    BTD700_STATE_NONE            = 0,
    BTD700_STATE_DISCONNECTED    = 1,
    BTD700_STATE_CONNECTED       = 2,
    BTD700_STATE_STREAMING_AUDIO = 3,
    BTD700_STATE_STREAMING_VOICE = 4,
} btd700_dongle_state_t;

typedef enum {
    BTD700_LE_AUDIO_NONE                = 0,
    BTD700_LE_AUDIO_DISCONNECTED        = 1,
    BTD700_LE_AUDIO_CONNECTED           = 2,
    BTD700_LE_AUDIO_STREAMING_UNICAST   = 3,
    BTD700_LE_AUDIO_STREAMING_BROADCAST = 4,
} btd700_le_audio_state_t;

typedef enum {
    BTD700_SINK_NOT_AVAILABLE = 0,
    BTD700_SINK_CLASSIC       = 1,
    BTD700_SINK_LE_AUDIO      = 2,
    BTD700_SINK_DUAL          = 3,
} btd700_sink_mode_t;

typedef enum {
    BTD700_BROADCAST_OFF_PRIVATE = 0,
    BTD700_BROADCAST_ON_PUBLIC   = 1,
} btd700_broadcast_state_t;

typedef enum {
    BTD700_BROADCAST_ENCRYPTION_OFF = 0,
    BTD700_BROADCAST_ENCRYPTION_ON  = 1,
} btd700_broadcast_encryption_t;

typedef enum {
    BTD700_BROADCAST_QUALITY_STANDARD_16K = 0,
    BTD700_BROADCAST_QUALITY_STANDARD_24K = 1,
    BTD700_BROADCAST_QUALITY_HIGH         = 2,
} btd700_broadcast_quality_t;

typedef enum {
    BTD700_EVENT_STATE_CHANGED              = 0,
    BTD700_EVENT_AUDIO_MODE_CHANGED         = 1,
    BTD700_EVENT_CODEC_CHANGED              = 2,
    BTD700_EVENT_LE_AUDIO_STATE_CHANGED     = 3,
    BTD700_EVENT_AUDIO_QUALITY_CHANGED      = 4,
    BTD700_EVENT_SINK_TRANSPORT_CHANGED     = 5,
    BTD700_EVENT_GAMING_AVAILABILITY_CHANGED = 6,
} btd700_event_type_t;

typedef struct {
    char manufacturer[256];
    char product[256];
    char serial[256];
} btd700_device_info_t;

typedef struct {
    uint8_t major;
    uint8_t minor;
    uint16_t build;
} btd700_firmware_version_t;

typedef struct {
    btd700_audio_mode_t mode;
    btd700_transport_mode_t transport;
} btd700_audio_config_t;

typedef struct {
    btd700_audio_frequency_t frequency;
    btd700_audio_resolution_t resolution;
} btd700_audio_quality_t;

typedef struct {
    btd700_broadcast_state_t state;
    btd700_broadcast_encryption_t encryption;
    btd700_broadcast_quality_t quality;
} btd700_broadcast_info_t;

typedef struct {
    btd700_event_type_t type;
    const uint8_t* data;
    size_t data_len;
} btd700_event_t;

typedef void (*btd700_event_callback_t)(const btd700_event_t* event, void* user_data);
typedef struct btd700_driver btd700_driver_t;

// ==========================================================================================
// features
// ==========================================================================================

BTD700_API btd700_error_t btd700_driver_create(btd700_driver_t** out);

BTD700_API void           btd700_driver_destroy(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_connect(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_disconnect(btd700_driver_t* drv);

BTD700_API int            btd700_driver_is_connected(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_device_info(btd700_driver_t* drv,
                                                     btd700_device_info_t* out);

BTD700_API btd700_error_t btd700_driver_firmware_version(btd700_driver_t* drv,
                                                          btd700_firmware_version_t* out);

BTD700_API btd700_error_t btd700_driver_state(btd700_driver_t* drv,
                                               btd700_dongle_state_t* out);

BTD700_API btd700_error_t btd700_driver_audio_config(btd700_driver_t* drv,
                                                      btd700_audio_config_t* out);

BTD700_API btd700_error_t btd700_driver_supported_codecs(btd700_driver_t* drv,
                                                          uint16_t* out);

BTD700_API btd700_error_t btd700_driver_active_codec(btd700_driver_t* drv,
                                                      uint16_t* out);

BTD700_API btd700_error_t btd700_driver_le_audio_state(btd700_driver_t* drv,
                                                        btd700_le_audio_state_t* out);

BTD700_API btd700_error_t btd700_driver_audio_quality(btd700_driver_t* drv,
                                                       btd700_audio_quality_t* out);

BTD700_API btd700_error_t btd700_driver_sink_transport(btd700_driver_t* drv,
                                                        btd700_sink_mode_t* out);

BTD700_API btd700_error_t btd700_driver_is_gaming_available(btd700_driver_t* drv,
                                                             int* out);

BTD700_API btd700_error_t btd700_driver_broadcast_info(btd700_driver_t* drv,
                                                        btd700_broadcast_info_t* out);

BTD700_API btd700_error_t btd700_driver_broadcast_name(btd700_driver_t* drv,
                                                        char* buf, size_t buf_size);

BTD700_API btd700_error_t btd700_driver_broadcast_key(btd700_driver_t* drv,
                                                       uint8_t* buf, size_t buf_size,
                                                       size_t* out_len);

BTD700_API btd700_error_t btd700_driver_set_audio_mode(btd700_driver_t* drv,
                                                        btd700_audio_mode_t mode,
                                                        btd700_transport_mode_t transport);

BTD700_API btd700_error_t btd700_driver_set_codec_mask(btd700_driver_t* drv,
                                                        uint16_t codec_mask);

BTD700_API btd700_error_t btd700_driver_set_codec(btd700_driver_t* drv,
                                                   btd700_codec_t codec);

BTD700_API btd700_error_t btd700_driver_set_broadcast_info(btd700_driver_t* drv,
                                                            btd700_broadcast_state_t state,
                                                            btd700_broadcast_encryption_t encryption,
                                                            btd700_broadcast_quality_t quality);

BTD700_API btd700_error_t btd700_driver_set_broadcast_name(btd700_driver_t* drv,
                                                            const char* name);

BTD700_API btd700_error_t btd700_driver_set_broadcast_key(btd700_driver_t* drv,
                                                           const uint8_t* key, size_t key_len);

BTD700_API btd700_error_t btd700_driver_trigger_connect(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_trigger_disconnect(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_factory_reset(btd700_driver_t* drv);

BTD700_API btd700_error_t btd700_driver_set_event_callback(btd700_driver_t* drv,
                                                            btd700_event_callback_t callback,
                                                            void* user_data);

BTD700_API btd700_error_t btd700_driver_poll_events(btd700_driver_t* drv,
                                                     int timeout_ms);

BTD700_API btd700_error_t btd700_driver_send_command(btd700_driver_t* drv,
                                                      uint8_t cmd,
                                                      const uint8_t* args, size_t args_len,
                                                      uint8_t* out_buf, size_t out_buf_size,
                                                      size_t* out_len);

// ==========================================================================================
// string helpers
// ==========================================================================================

BTD700_API const char* btd700_audio_mode_string(btd700_audio_mode_t mode);

BTD700_API const char* btd700_transport_mode_string(btd700_transport_mode_t mode);

BTD700_API const char* btd700_dongle_state_string(btd700_dongle_state_t state);

BTD700_API const char* btd700_le_audio_state_string(btd700_le_audio_state_t state);

BTD700_API const char* btd700_sink_mode_string(btd700_sink_mode_t mode);

BTD700_API const char* btd700_codec_string(btd700_codec_t codec);

BTD700_API const char* btd700_audio_frequency_string(btd700_audio_frequency_t freq);

BTD700_API const char* btd700_audio_resolution_string(btd700_audio_resolution_t res);

BTD700_API const char* btd700_broadcast_state_string(btd700_broadcast_state_t state);

BTD700_API const char* btd700_broadcast_encryption_string(btd700_broadcast_encryption_t enc);

BTD700_API const char* btd700_broadcast_quality_string(btd700_broadcast_quality_t quality);

BTD700_API const char* btd700_error_string(btd700_error_t err);

#ifdef __cplusplus
}
#endif

#endif /* BTD700_C_H */
