# include "fbcu.bi"

#if __FB_BACKEND__ = "gas"

namespace fbc_tests.functions.naked_ctor

type Nested
	as integer i
	declare constructor( )
	declare destructor( )
end type

constructor Nested( )
	'' Shouldn't be implicitly called by Parent's Naked constructor
	CU_FAIL( )
end constructor

destructor Nested( )
	'' Shouldn't be implicitly called by Parent's Naked destructor
	CU_FAIL( )
end destructor


type Parent
	as Nested foo

	declare constructor naked cdecl( )
	declare destructor naked cdecl( )
end type

constructor Parent naked cdecl( )
	asm
		mov eax, dword ptr [esp+4]   '' Get THIS ptr parameter
		mov dword ptr [eax], 123     '' Set first 4-byte field
		ret
	end asm
end constructor

destructor Parent naked cdecl( )
	asm
		ret
	end asm
end destructor

private sub test cdecl( )
	dim as Parent x
	CU_ASSERT( x.foo.i = 123 )
end sub

private sub ctor( ) constructor
	fbcu.add_suite( "fbc_tests.functions.naked-ctor")
	fbcu.add_test( "Naked constructors/destructors", @test )
end sub

end namespace

#endif
