package com.codeazur.as3swf.data.abc.exporters.builders.js
{

	import com.codeazur.as3swf.data.abc.ABC;
	import com.codeazur.as3swf.data.abc.bytecode.ABCMethodBody;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcode;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcodeKind;
	import com.codeazur.as3swf.data.abc.bytecode.ABCOpcodeSet;
	import com.codeazur.as3swf.data.abc.bytecode.ABCParameter;
	import com.codeazur.as3swf.data.abc.bytecode.IABCMultiname;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeAttribute;
	import com.codeazur.as3swf.data.abc.bytecode.attributes.ABCOpcodeMultinameUIntAttribute;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCDebugBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCMethodOpcodeBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.IABCValueBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.js.debug.JSDebugBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.js.debug.JSDebugFileBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.js.debug.JSDebugLineBuilder;
	import com.codeazur.as3swf.data.abc.exporters.builders.js.expressions.JSThisExpression;
	import com.codeazur.as3swf.data.abc.io.IABCWriteable;

	import flash.utils.ByteArray;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSMethodOpcodeBuilder implements IABCMethodOpcodeBuilder {
		
		private var _parameters:Vector.<ABCParameter>;
		private var _methodBody:ABCMethodBody;
		private var _returnType:IABCMultiname;
		private var _enableDebug:Boolean;
		
		public function JSMethodOpcodeBuilder() {
			_enableDebug = false;
		}
		
		public static function create(parameters:Vector.<ABCParameter>, methodBody:ABCMethodBody, returnType:IABCMultiname):JSMethodOpcodeBuilder {
			const builder:JSMethodOpcodeBuilder = new JSMethodOpcodeBuilder();
			builder.parameters = parameters;
			builder.methodBody = methodBody;
			builder.returnType = returnType;
			return builder;
		}

		public function write(data : ByteArray) : void {
			const opcodes:ABCOpcodeSet = methodBody.opcode;
			const total:uint = opcodes.length;
			if(total > 0) {
				var pending:Boolean = false;
				var item:IABCWriteable;
				
				const scope:Vector.<IABCWriteable> = new Vector.<IABCWriteable>();
				const stack:Vector.<IABCWriteable> = new Vector.<IABCWriteable>();
				const params:Vector.<JSParameterBuilder> = new Vector.<JSParameterBuilder>();
								
				// Build method args
				for(var i:uint=0; i<total; i++) {
					const opcode:ABCOpcode = opcodes.getAt(i);
					const kind:ABCOpcodeKind = opcode.kind;
					
					if(!ABCOpcodeKind.isDebug(kind)) {
						switch(kind) {
							case ABCOpcodeKind.CALLPROPERTY:
								const numArguments:uint = getNumberArguments(opcode.attribute);
								
								scope.length = 0;
								scope[0] = stack[stack.length - numArguments];
								
								params.length = 0;
								for(var j:uint=1; j<numArguments; j++) {
									const writeable:IABCWriteable = stack[(stack.length - numArguments) + j];
									if(writeable is JSParameterBuilder) {
										params.push(writeable);
									} else {
										//
									}
								}
								
								const method:IABCValueBuilder = JSValueAttributeBuilder.create(opcode.attribute);
								item = JSMethodCallBuilder.create(scope, method, params);
								item.write(data);
								stack.push(item);
								pending = true;
								break;
							
							case ABCOpcodeKind.CONSTRUCTSUPER:
								scope.length = 0;
								scope[0] = stack[stack.length - 1];
								
								const superctorMethod:IABCValueBuilder = JSValueBuilder.create(JSReservedKind.SUPER.type);
								item = JSMethodCallBuilder.create(scope, superctorMethod);
								item.write(data);
								stack.push(item);
								pending = true;
								break;
							
							case ABCOpcodeKind.GETLOCAL_0:
								if(pending) {
									pending = false;
									JSTokenKind.SEMI_COLON.write(data);
								}
								stack.push(JSThisExpression.create());
								break;
							
							case ABCOpcodeKind.GETLOCAL_1:
								stack.push(JSParameterBuilder.create(parameters[0]));
								break;
								
							case ABCOpcodeKind.PUSHSCOPE:
								scope.length = 0;
								scope[0] = stack[stack.length - 1];
								
								item = JSAccessorBuilder.create(scope);
								item.write(data);
								stack.push(item);
								pending = true;
								break;
							
							case ABCOpcodeKind.POP:
								stack.pop();
								break;
								
							case ABCOpcodeKind.RETURNVOID:
								if(pending) {
									pending = false;
									JSTokenKind.SEMI_COLON.write(data);
								}
								JSReservedKind.RETURN.write(data);
								JSTokenKind.SEMI_COLON.write(data);
								break;
								
							default:
								trace(kind);
								break;
						}
					} else {
						// Don't push this on the stack!
						if(enableDebug) {
							if(pending) {
								pending = false;
								JSTokenKind.SEMI_COLON.write(data);
							}
							switch(kind) {
								case ABCOpcodeKind.DEBUG:
									const debug:IABCDebugBuilder = JSDebugBuilder.create(opcode.attribute);
									debug.write(data);
									break;
									
								case ABCOpcodeKind.DEBUGFILE:
									const debugFile:IABCDebugBuilder = JSDebugFileBuilder.create(opcode.attribute);
									debugFile.write(data);
									break;
									
								case ABCOpcodeKind.DEBUGLINE:
									const debugLine:IABCDebugBuilder = JSDebugLineBuilder.create(opcode.attribute);
									debugLine.write(data);
									break;
								
								default:
									throw new Error();
							}
						}
					}
				}
			}
		}
		
		private function getNumberArguments(attribute:ABCOpcodeAttribute):uint {
			var numArguments:uint = 1;
			if(attribute is ABCOpcodeMultinameUIntAttribute){
				numArguments = ABCOpcodeMultinameUIntAttribute(attribute).numArguments + 1;
			}
			return numArguments;
		}
		
		public function get parameters():Vector.<ABCParameter> { return _parameters; }
		public function set parameters(value:Vector.<ABCParameter>):void { _parameters = value; }
			
		public function get methodBody():ABCMethodBody { return _methodBody; }
		public function set methodBody(value:ABCMethodBody):void { _methodBody = value; }
		
		public function get returnType():IABCMultiname { return _returnType; }
		public function set returnType(value:IABCMultiname):void { _returnType = value; }
		
		public function get enableDebug() : Boolean { return _enableDebug; }
		public function set enableDebug(value : Boolean) : void { _enableDebug = value;	}
		
		public function get name():String { return "JSMethodOpcodeBuilder"; }
		
		public function toString(indent:uint=0):String {
			return ABC.toStringCommon(name, indent);
		}
	}
}