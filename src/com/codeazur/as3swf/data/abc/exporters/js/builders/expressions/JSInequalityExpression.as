package com.codeazur.as3swf.data.abc.exporters.js.builders.expressions
{

	import com.codeazur.as3swf.data.abc.exporters.builders.IABCExpression;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSConsumableBlock;
	import com.codeazur.as3swf.data.abc.exporters.js.builders.JSOperatorKind;
	import com.codeazur.as3swf.data.abc.io.IABCWriteable;

	import flash.utils.ByteArray;
	/**
	 * @author Simon Richardson - simon@ustwo.co.uk
	 */
	public class JSInequalityExpression extends JSConsumableBlock implements IABCExpression {

		public function JSInequalityExpression() {
		}

		public static function create(left:IABCWriteable = null, right:IABCWriteable = null):JSInequalityExpression {
			const expression:JSInequalityExpression = new JSInequalityExpression();
			expression.left = left;
			expression.right = right;
			return expression;
		}

		override public function write(data:ByteArray):void {
			if(!right) {
				JSOperatorKind.LOGICAL_NOT.write(data);
				left.write(data);
			} else {
				left.write(data);
				JSOperatorKind.STRICT_INEQUALITY.write(data);
				right.write(data);
			}
		}
		
		override public function get name():String { return "JSInequalityExpression"; }
	}
}
