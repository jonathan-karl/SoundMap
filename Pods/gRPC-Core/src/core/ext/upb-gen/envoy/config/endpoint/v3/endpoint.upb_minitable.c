/* This file was generated by upb_generator from the input file:
 *
 *     envoy/config/endpoint/v3/endpoint.proto
 *
 * Do not edit -- your changes will be discarded when the file is
 * regenerated. */

#include <stddef.h>
#include "upb/generated_code_support.h"
#include "envoy/config/endpoint/v3/endpoint.upb_minitable.h"
#include "envoy/config/endpoint/v3/endpoint_components.upb_minitable.h"
#include "envoy/type/v3/percent.upb_minitable.h"
#include "google/protobuf/duration.upb_minitable.h"
#include "google/protobuf/wrappers.upb_minitable.h"
#include "udpa/annotations/status.upb_minitable.h"
#include "udpa/annotations/versioning.upb_minitable.h"
#include "validate/validate.upb_minitable.h"

// Must be last.
#include "upb/port/def.inc"

static const upb_MiniTableSub envoy_config_endpoint_v3_ClusterLoadAssignment_submsgs[3] = {
  {.submsg = &envoy__config__endpoint__v3__LocalityLbEndpoints_msg_init},
  {.submsg = &envoy__config__endpoint__v3__ClusterLoadAssignment__Policy_msg_init},
  {.submsg = &envoy__config__endpoint__v3__ClusterLoadAssignment__NamedEndpointsEntry_msg_init},
};

static const upb_MiniTableField envoy_config_endpoint_v3_ClusterLoadAssignment__fields[4] = {
  {1, UPB_SIZE(16, 8), 0, kUpb_NoSub, 9, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_StringView << kUpb_FieldRep_Shift)},
  {2, UPB_SIZE(4, 24), 0, 0, 11, (int)kUpb_FieldMode_Array | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
  {4, UPB_SIZE(8, 32), 1, 1, 11, (int)kUpb_FieldMode_Scalar | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
  {5, UPB_SIZE(12, 40), 0, 2, 11, (int)kUpb_FieldMode_Map | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
};

const upb_MiniTable envoy__config__endpoint__v3__ClusterLoadAssignment_msg_init = {
  &envoy_config_endpoint_v3_ClusterLoadAssignment_submsgs[0],
  &envoy_config_endpoint_v3_ClusterLoadAssignment__fields[0],
  UPB_SIZE(24, 48), 4, kUpb_ExtMode_NonExtendable, 2, UPB_FASTTABLE_MASK(56), 0,
  UPB_FASTTABLE_INIT({
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x000800003f00000a, &upb_pss_1bt},
    {0x001800003f000012, &upb_prm_1bt_maxmaxb},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x0020000001010022, &upb_psm_1bt_max64b},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
  })
};

static const upb_MiniTableSub envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_submsgs[3] = {
  {.submsg = &envoy__config__endpoint__v3__ClusterLoadAssignment__Policy__DropOverload_msg_init},
  {.submsg = &google__protobuf__UInt32Value_msg_init},
  {.submsg = &google__protobuf__Duration_msg_init},
};

static const upb_MiniTableField envoy_config_endpoint_v3_ClusterLoadAssignment_Policy__fields[4] = {
  {2, UPB_SIZE(4, 8), 0, 0, 11, (int)kUpb_FieldMode_Array | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
  {3, UPB_SIZE(8, 16), 1, 1, 11, (int)kUpb_FieldMode_Scalar | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
  {4, UPB_SIZE(12, 24), 2, 2, 11, (int)kUpb_FieldMode_Scalar | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
  {6, UPB_SIZE(16, 1), 0, kUpb_NoSub, 8, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_1Byte << kUpb_FieldRep_Shift)},
};

const upb_MiniTable envoy__config__endpoint__v3__ClusterLoadAssignment__Policy_msg_init = {
  &envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_submsgs[0],
  &envoy_config_endpoint_v3_ClusterLoadAssignment_Policy__fields[0],
  UPB_SIZE(24, 32), 4, kUpb_ExtMode_NonExtendable, 0, UPB_FASTTABLE_MASK(56), 0,
  UPB_FASTTABLE_INIT({
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x000800003f000012, &upb_prm_1bt_max64b},
    {0x001000000101001a, &upb_psm_1bt_maxmaxb},
    {0x0018000002020022, &upb_psm_1bt_maxmaxb},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x000100003f000030, &upb_psb1_1bt},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
  })
};

static const upb_MiniTableSub envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_DropOverload_submsgs[1] = {
  {.submsg = &envoy__type__v3__FractionalPercent_msg_init},
};

static const upb_MiniTableField envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_DropOverload__fields[2] = {
  {1, 8, 0, kUpb_NoSub, 9, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_StringView << kUpb_FieldRep_Shift)},
  {2, UPB_SIZE(4, 24), 1, 0, 11, (int)kUpb_FieldMode_Scalar | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
};

const upb_MiniTable envoy__config__endpoint__v3__ClusterLoadAssignment__Policy__DropOverload_msg_init = {
  &envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_DropOverload_submsgs[0],
  &envoy_config_endpoint_v3_ClusterLoadAssignment_Policy_DropOverload__fields[0],
  UPB_SIZE(16, 32), 2, kUpb_ExtMode_NonExtendable, 2, UPB_FASTTABLE_MASK(24), 0,
  UPB_FASTTABLE_INIT({
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x000800003f00000a, &upb_pss_1bt},
    {0x0018000001000012, &upb_psm_1bt_maxmaxb},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
  })
};

static const upb_MiniTableSub envoy_config_endpoint_v3_ClusterLoadAssignment_NamedEndpointsEntry_submsgs[1] = {
  {.submsg = &envoy__config__endpoint__v3__Endpoint_msg_init},
};

static const upb_MiniTableField envoy_config_endpoint_v3_ClusterLoadAssignment_NamedEndpointsEntry__fields[2] = {
  {1, 8, 0, kUpb_NoSub, 9, (int)kUpb_FieldMode_Scalar | ((int)kUpb_FieldRep_StringView << kUpb_FieldRep_Shift)},
  {2, UPB_SIZE(16, 24), 1, 0, 11, (int)kUpb_FieldMode_Scalar | ((int)UPB_SIZE(kUpb_FieldRep_4Byte, kUpb_FieldRep_8Byte) << kUpb_FieldRep_Shift)},
};

const upb_MiniTable envoy__config__endpoint__v3__ClusterLoadAssignment__NamedEndpointsEntry_msg_init = {
  &envoy_config_endpoint_v3_ClusterLoadAssignment_NamedEndpointsEntry_submsgs[0],
  &envoy_config_endpoint_v3_ClusterLoadAssignment_NamedEndpointsEntry__fields[0],
  UPB_SIZE(24, 40), 2, kUpb_ExtMode_NonExtendable, 2, UPB_FASTTABLE_MASK(24), 0,
  UPB_FASTTABLE_INIT({
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
    {0x000800003f00000a, &upb_pss_1bt},
    {0x0018000001000012, &upb_psm_1bt_maxmaxb},
    {0x0000000000000000, &_upb_FastDecoder_DecodeGeneric},
  })
};

static const upb_MiniTable *messages_layout[4] = {
  &envoy__config__endpoint__v3__ClusterLoadAssignment_msg_init,
  &envoy__config__endpoint__v3__ClusterLoadAssignment__Policy_msg_init,
  &envoy__config__endpoint__v3__ClusterLoadAssignment__Policy__DropOverload_msg_init,
  &envoy__config__endpoint__v3__ClusterLoadAssignment__NamedEndpointsEntry_msg_init,
};

const upb_MiniTableFile envoy_config_endpoint_v3_endpoint_proto_upb_file_layout = {
  messages_layout,
  NULL,
  NULL,
  4,
  0,
  0,
};

#include "upb/port/undef.inc"
