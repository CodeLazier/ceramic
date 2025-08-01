package ceramic;

using ceramic.Extensions;

/**
 * Deep equality comparison utilities for various data types.
 * 
 * Equal provides comprehensive equality checking that goes beyond simple
 * reference comparison. It supports deep comparison of arrays, maps,
 * and anonymous objects, making it useful for data validation, testing,
 * and change detection.
 * 
 * ## Supported Types
 * 
 * - **Arrays**: Element-by-element comparison (shallow)
 * - **StringMap**: Key-value comparison
 * - **IntMap**: Key-value comparison  
 * - **Anonymous Objects**: Field-by-field comparison (recursive)
 * - **Primitives**: Standard equality
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Array comparison
 * var a1 = [1, 2, 3];
 * var a2 = [1, 2, 3];
 * Equal.equal(a1, a2); // true
 * 
 * // Object comparison
 * var o1 = {x: 10, y: 20, data: [1, 2]};
 * var o2 = {x: 10, y: 20, data: [1, 2]};
 * Equal.equal(o1, o2); // true
 * 
 * // Map comparison
 * var m1 = new StringMap<Int>();
 * m1.set("a", 1);
 * var m2 = new StringMap<Int>();
 * m2.set("a", 1);
 * Equal.equal(m1, m2); // true
 * ```
 * 
 * ## Limitations
 * 
 * - Array comparison is shallow (doesn't recurse into nested arrays)
 * - Class instances are compared by reference only
 * - Circular references will cause infinite recursion
 * 
 * @see ceramic.Extensions For array utility methods
 */
class Equal {

    /**
     * Performs deep equality comparison between two values.
     * 
     * Compares values based on their type:
     * - Same reference: true
     * - Arrays: Element-by-element comparison
     * - Maps: Key-value comparison
     * - Anonymous objects: Field comparison (recursive)
     * - Other: Reference equality
     * 
     * @param a First value to compare
     * @param b Second value to compare
     * @return True if values are deeply equal, false otherwise
     * 
     * @example
     * ```haxe
     * // Simple values
     * Equal.equal(5, 5); // true
     * Equal.equal("hello", "hello"); // true
     * 
     * // Arrays
     * Equal.equal([1, 2, 3], [1, 2, 3]); // true
     * Equal.equal([1, 2], [1, 2, 3]); // false
     * 
     * // Objects
     * Equal.equal(
     *     {name: "John", age: 30},
     *     {name: "John", age: 30}
     * ); // true
     * ```
     */
    public static function equal(a:Dynamic, b:Dynamic):Bool {

        if (a == b)
            return true;

        if (Std.isOfType(a, Array)) {
            if (Std.isOfType(b, Array)) {
                return _arrayEqual(a, b);
            }
            return false;
        }
        else if (Std.isOfType(a, haxe.ds.StringMap)) {
            if (Std.isOfType(b, haxe.ds.StringMap)) {
                return stringMapEqual(a, b);
            }
            return false;
        }
        else if (Std.isOfType(a, haxe.ds.IntMap)) {
            if (Std.isOfType(b, haxe.ds.IntMap)) {
                return intMapEqual(a, b);
            }
            return false;
        }
        else if (Reflect.isObject(a) && Type.getClass(a) == null) {
            if (Reflect.isObject(b) && Type.getClass(b) == null) {
                return objectFieldsEqual(a, b);
            }
            return false;
        }

        return false;

    }

    /**
     * Compares two anonymous objects by their fields.
     * 
     * Performs recursive comparison of all fields in both objects.
     * Objects are considered equal if they have the same fields
     * with equal values (using the equal() function).
     * 
     * @param a First object to compare
     * @param b Second object to compare  
     * @return True if all fields match, false otherwise
     * 
     * @example
     * ```haxe
     * var obj1 = {x: 10, y: {z: 20}};
     * var obj2 = {x: 10, y: {z: 20}};
     * Equal.objectFieldsEqual(obj1, obj2); // true
     * 
     * var obj3 = {x: 10, y: 20, extra: true};
     * Equal.objectFieldsEqual(obj1, obj3); // false (different fields)
     * ```
     */
    public static function objectFieldsEqual(a:Any, b:Any):Bool {
        for (field in Reflect.fields(a)) {
            if (!Reflect.hasField(b, field) || !equal(Reflect.field(a, field), Reflect.field(b, field))) {
                return false;
            }
        }
        for (field in Reflect.fields(b)) {
            if (!Reflect.hasField(a, field)) {
                return false;
            }
        }
        return true;
    }

    #if cs
    /**
     * Specialized array comparison for C# string arrays.
     * Works around C# type system limitations.
     */
    public extern inline static overload function arrayEqual(a:Array<String>, b:Array<String>):Bool {
        var aDyn:Any = a;
        var bDyn:Any = b;
        return _arrayEqual(cast aDyn, cast bDyn);
    }
    #end

    /**
     * Compares two arrays element by element.
     * 
     * Arrays are equal if they have the same length and all
     * corresponding elements are equal (using == comparison).
     * 
     * @param a First array
     * @param b Second array
     * @return True if arrays are equal
     */
    public extern inline static overload function arrayEqual(a:Array<Any>, b:Array<Any>):Bool {
        return _arrayEqual(a, b);
    }

    /**
     * Internal array comparison implementation.
     * Uses unsafe array access for performance.
     */
    public static function _arrayEqual(a:Array<Any>, b:Array<Any>):Bool {

        var lenA = a.length;
        var lenB = b.length;
        if (lenA != lenB)
            return false;
        for (i in 0...lenA) {
            if (a.unsafeGet(i) != b.unsafeGet(i)) {
                return false;
            }
        }
        return true;

    }

    /**
     * Compares two StringMaps by their key-value pairs.
     * 
     * Maps are equal if they have the same keys and all values
     * for corresponding keys are equal (using == comparison).
     * 
     * @param a First StringMap
     * @param b Second StringMap
     * @return True if maps have identical key-value pairs
     * 
     * @example
     * ```haxe
     * var map1 = new StringMap<Int>();
     * map1.set("a", 1);
     * map1.set("b", 2);
     * 
     * var map2 = new StringMap<Int>();
     * map2.set("b", 2);
     * map2.set("a", 1);
     * 
     * Equal.stringMapEqual(map1, map2); // true (order doesn't matter)
     * ```
     */
    public static function stringMapEqual(a:haxe.ds.StringMap<Any>, b:haxe.ds.StringMap<Any>):Bool {

        for (key => val in a) {
            if (!b.exists(key))
                return false;
            if (b.get(key) != val)
                return false;
        }

        for (key in b.keys()) {
            if (!a.exists(key))
                return false;
        }

        return true;

    }

    /**
     * Compares two IntMaps by their key-value pairs.
     * 
     * Maps are equal if they have the same keys and all values
     * for corresponding keys are equal (using == comparison).
     * 
     * @param a First IntMap
     * @param b Second IntMap
     * @return True if maps have identical key-value pairs
     * 
     * @example
     * ```haxe
     * var map1 = new IntMap<String>();
     * map1.set(1, "one");
     * map1.set(2, "two");
     * 
     * var map2 = new IntMap<String>();
     * map2.set(2, "two");
     * map2.set(1, "one");
     * 
     * Equal.intMapEqual(map1, map2); // true
     * ```
     */
    public static function intMapEqual(a:haxe.ds.IntMap<Any>, b:haxe.ds.IntMap<Any>):Bool {

        for (key => val in a) {
            if (!b.exists(key))
                return false;
            if (b.get(key) != val)
                return false;
        }

        for (key in b.keys()) {
            if (!a.exists(key))
                return false;
        }

        return true;

    }

}