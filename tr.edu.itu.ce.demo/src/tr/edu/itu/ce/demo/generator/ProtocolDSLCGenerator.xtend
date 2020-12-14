package tr.edu.itu.ce.demo.generator

import java.util.Date
import tr.edu.itu.ce.demo.protocolDSl.BitMask
import tr.edu.itu.ce.demo.protocolDSl.Csum
import tr.edu.itu.ce.demo.protocolDSl.Entry
import tr.edu.itu.ce.demo.protocolDSl.EnumSpec
import tr.edu.itu.ce.demo.protocolDSl.Message
import tr.edu.itu.ce.demo.protocolDSl.Protocol
import tr.edu.itu.ce.demo.protocolDSl.Spec
import javax.inject.Inject

class ProtocolDSLCGenerator {
	@Inject extension ProtocolDSLGenUtils utils
		
	def generateMakefile(Protocol protocol) '''
		LIB_NAME=«protocol.name»
		TOOLCHAIN_PREFIX=
		
		AR=$(TOOLCHAIN_PREFIX)ar
		CC=$(TOOLCHAIN_PREFIX)gcc
		GDB=$(TOOLCHAIN_PREFIX)gdb
		OBJCOPY=$(TOOLCHAIN_PREFIX)objcopy
		NM=$(TOOLCHAIN_PREFIX)nm
		SIZE=$(TOOLCHAIN_PREFIX)size
		STRIP=$(TOOLCHAIN_PREFIX)strip
		READELF=$(TOOLCHAIN_PREFIX)readelf
		
		OPT := -O0 -g3
		
		ifdef RELEASE
		OPT := -O3
		endif
		
		ifdef SIZEOPT
		OPT := -Os
		endif
		
		SHAREDFLABS := $(OPT)
		AFLAGS := -c -x assembler $(SHAREDFLAGS) -Wa,-I.
		
		CFLAGS := -c $(SHAREDFLAGS) -std=c99 -fPIC
		
		«FOR msg : protocol.messages»
		SRCS += «msg.name».c
		«ENDFOR»
		
		OBJS := $(SRCS:.c=.o)
		DEPS := $(SRCS:.c=.d)
		
		.PHONY: $(LIB_NAME)_lib.a $(LIB_NAME)_lib_py.so
		
		all: $(LIB_NAME)_lib.a $(LIB_NAME)_lib_py.so test
		rebuild: clean all
		
		proj: $(LIB_NAME)_lib.a
		
		-include $(DEPS)
		
		%.o: %.c
			@echo CC $<
			@$(CC) -c $(CFLAGS) $< -o $@
			@$(CC) $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
			
		$(LIB_NAME)_lib.a: $(OBJS)
			@echo AR $@
			@$(AR) rcs $@ $^
			
			@$(SIZE) $(LIB_NAME)_lib.a
			
		$(LIB_NAME)_lib_py.so: $(OBJS)
			@$(CC) -shared -fPIC -o $(LIB_NAME)_lib_py.so $^
			
		test:
			python3 suite.py
			
		clean:
			@echo RM
			@rm -f *.o *.d *.a *.so 
	'''
	
	def generateCompilerH() '''
		typedef unsigned char u8;
		typedef unsigned short u16;
		typedef unsigned int u32;
		typedef unsigned long u64;
		
		typedef signed char s8;
		typedef signed short s16;
		typedef signed int s32;
		typedef signed long s64;
		
		typedef float r32;
		typedef double r64;
	'''
	
	def generateMessageCHeader(Message msg) '''
		// -------------------------------------------------------------
		// Protocol «(msg.eContainer as Protocol).name»
		// Message  «msg.name»
		// Date     «new Date(System.currentTimeMillis)»
		// 
		// Generated code. Please do not modify.
		// -------------------------------------------------------------
		
		#include "Compiler.h"
		
		«FOR e : msg.entries.filter(EnumSpec)»
			«generateEnumDef(e)»
		«ENDFOR»
		
		«FOR e : msg.entries.filter(BitMask)»
			«generateBitmaskDef(e)»
		«ENDFOR»
		
		typedef struct {
			«FOR e : msg.entries»
				«generateEntry(e)»
			«ENDFOR»
		} s_«msg.name»_msg;
		
		typedef union {
			u8 u8[sizeof(«msg.s_name»)];
			s_«msg.name»_msg msg;
		} t_«msg.name»_msg;
	'''

	def generateEnumDef(EnumSpec e) '''
		typedef enum {
			«FOR v : e.entries SEPARATOR ','»
				«v.name.toUpperCase»«IF v.value!==null» = «v.value.c_hex» «ENDIF»
			«ENDFOR»
		} «e.c_name»;
	'''

	def generateBitmaskDef(BitMask bm) '''
		typedef struct {
			«FOR region : bm.regions»
				«bm.type» «region.name» : «region.width»;
			«ENDFOR»
		} «bm.s_name»;
	'''

	def dispatch generateEntry(Spec spec) '''
		«spec.type» «spec.name»«IF spec.count>1»[«spec.count»]«ENDIF»;
	'''

	def dispatch generateEntry(BitMask bm) '''
		union {
			u8 u8[sizeof(«bm.s_name»)];
			«bm.s_name» bits;
		} «bm.name»;
	'''

	def dispatch generateEntry(EnumSpec enm) '''«enm.type» «enm.name»;'''
	
	def dispatch generateEntry(Csum csum) '''«csum.type» «csum.name»;'''

	def generateMessageCSource(Message msg) '''
		// -------------------------------------------------------------
		// Protocol «(msg.eContainer as Protocol).name»
		// Message  «msg.name»
		// Date     «new Date(System.currentTimeMillis)»
		// 
		// Generated code. Please do not modify.
		// -------------------------------------------------------------
		
		#include <string.h>
		#include "«msg.name».h"
		
		#define MAX_BYTES_IN_A_CALL (sizeof(«msg.t_name»)*2)
		#define «msg.name.toUpperCase»_MSG_SIZE (sizeof(«msg.t_name»))
		
		t_«msg.name»_msg «msg.name»_msg;
		
		typedef enum {
			«FOR e : msg.entries SEPARATOR ','»
				«e.rx_st_name»
			«ENDFOR»
		} «msg.name»_states_enum;
		
		u8 «msg.name»_rx_buffer[sizeof(«msg.t_name»)];
		
		u8 «msg.name»_rx_msg_i=0;
		u8 «msg.name»_rx_section_i=0;
		«msg.name»_states_enum «msg.name»_rx_state = «msg.entries.head.rx_st_name»;
		
		void reset_«msg.name»_rx() {
			memset( «msg.name»_rx_buffer, 0,  sizeof(«msg.name»_rx_buffer) );
			«msg.name»_rx_msg_i = 0;
			«msg.name»_rx_section_i = 0;
			«msg.name»_rx_state = «msg.entries.head.rx_st_name»;
		}

		
		int process_«msg.name»_rx_byte(u8 data) {
			«msg.name»_rx_buffer[«msg.name»_rx_msg_i++] = data;
			«msg.name»_rx_section_i++;
			
			switch( «msg.name»_rx_state ) {
			«FOR e : msg.entries»
				case «e.rx_st_name»: {
					«generateMatcher(e)»
					break;
				}
				
			«ENDFOR»
			} // switch
			
			return 0;
		}
	'''

	def dispatch generateMatcher(Spec spec) '''
		«val msg=spec.parent_msg»
		«IF spec.value !== null»
			// Matching values
			u8 values[] = { «FOR v : spec.value.items SEPARATOR ','»«v.c_hex»«ENDFOR» };
			if( data != values[«msg.name»_rx_section_i-1] ) {
				reset_«msg.name»_rx();
				return -1;
			}

		«ENDIF»
		// Transition
		«generateTransition(spec)»
	'''

	def dispatch generateMatcher(Entry e) '''
		«generateTransition(e)»
	'''

	def generateTransition(Entry e) '''
		«val msg = e.parent_msg»
		if(«msg.name»_rx_section_i >= «e.sizeof») {
			«msg.name»_rx_section_i = 0;
			«val next = e.next»
			«IF next!==null»
				«msg.name»_rx_state = «next.rx_st_name»;
			«ELSE»
				// successfully received the message. Copying buffer to instance.
				memcpy(«msg.name»_msg.u8, «msg.name»_rx_buffer, sizeof(«msg.name»_msg));
				reset_«msg.name»_rx();
				return 1;
			«ENDIF»
		}
	'''
	
	def dispatch generateMatcher(Csum csum) '''
		«val msg = csum.parent_msg»
		u32 size = «csum.sizeof»;
		
		if(«msg.name»_rx_section_i >= size) {
			«csum.type» calc_csum = 0x0000;
			
			for(int i=0; i<«msg.name»_rx_msg_i-size; i++)
				calc_csum+=«msg.name»_rx_buffer[i];
			
			«csum.type» rx_csum = 0;
			for(int i=0; i<size; i++)
				rx_csum = rx_csum<<8 | «msg.name»_rx_buffer[«msg.name»_rx_msg_i-size+i];
			
			if(calc_csum!=rx_csum) {
				reset_«msg.name»_rx();
				return -1;
			}
		}
		
		// Transition
		«generateTransition(csum)»
	'''
	

	def addr_ptr(Csum csum) '''&((t_«csum.parent_msg_name»_msg *)«csum.parent_msg_name»_rx_buffer)->msg.«csum.name.toUpperCase»'''
	
	def selector(Entry e) '''«e.parent_msg_name»_msg.msg.«e.name.toUpperCase»'''

	def sizeof(Entry e) '''sizeof(«e.selector»)'''

	def rx_st_name(Entry e) '''«e.parent_msg_name.toString.toUpperCase»_RX_READ_«e.name.toUpperCase»'''

	def t_name(Message msg) '''t_«msg.name»_msg'''

	def s_name(Message msg) '''s_«msg.name»_msg'''

	def s_name(BitMask bm) '''s_«bm.parent_msg_name»_«bm.name.toLowerCase»'''

	def c_name(EnumSpec e) {
		val msgName = (e.eContainer as Message).name
		'''«msgName»_«e.name.toLowerCase»_enum'''
	}
}