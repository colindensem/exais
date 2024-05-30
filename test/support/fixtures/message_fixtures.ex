defmodule ExAIS.MessageFixtures do

  @messages ["\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,33aKV05P00PG@O@N7gI@0?wT2>`<,0*3C",
     "\\p:spire,s:terrestrial,c:1692781249*54\\!AIVDM,1,1,,B,B3MA@I007?sDoVW;bE=23wpUoP06,0*4B",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,13cgCP0wi`176I0EgB<7U61L0>`<,0*10",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,B5NWW<P00=kd7T6t:c2uOwq5oP06,0*3B",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H0qH9Wl000000000000000000000,0*56",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,13MC:58P00WK=P>0fG=@kwwT2>`<,0*02",
     "\\p:spire,s:terrestrial,c:1692781250*5C\\!AIVDM,1,1,,A,B4hE8f000889fWV?448l7wq5oP06,0*1B",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,13m`WR00001G4VLWpb5d8p9l00T9,0*10",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H3@pcu4TCBD:MfPH@9kopj10321t,0*76",
     "\\p:spire,s:terrestrial,c:1692781257*5B\\!AIVDM,1,1,,B,177>p2002@0DOq:QO@5=EbWj0<07,0*2D",
     "\\p:spire,s:terrestrial,c:1692781243*5E\\!AIVDM,1,1,,B,16<g:S@P008WWQL=oR67rwwF0@H6,0*1E",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,B52OcB@00=pLF>4o3TbF;wpUoP06,0*7F",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,35R`V2002t0hVidVBtvPiPcl83Wk,0*74",
     "\\p:spire,s:terrestrial,c:1692781250*5C\\!AIVDM,1,1,,B,13kigf00111<frBP4`lBE1kT0>`<,0*4C",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,H42O>ClU9=1B9>5I=1jnqm00?050,0*72",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,13@oJQOu@IOgww<NdU2A3PuP0>`<,0*2C",
     "\\p:spire,s:terrestrial,c:1692781204*5D\\!AIVDM,1,1,,A,15Nd;9dOh3qTO`t@t`8:bbb80d4P,0*38",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,H5MCJcTTCBD6v:w00000001P1140,0*62",
     "\\p:spire,g:1-2-7337123,s:terrestrial,c:1692781258*16\\!AIVDM,2,1,3,A,53aDr3D000010KW?780Tp4000000000000000016;h<66v8605RiB3000000,0*62",
     "\\p:spire,g:2-2-7337123*6D\\!AIVDM,2,2,3,A,00000000000,2*27",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,B3KF;DP0AH:tsSWhAuRAKwq5oP06,0*78",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,A,H3TmNt4U>F36Ie5CF1nqpn106440,0*69",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,A,H3tfbw4U1=30000C6plhoP000000,0*3A",
     "\\p:spire,s:terrestrial,c:1692781258*54\\!AIVDM,1,1,,B,H7OmE<4UCBD:MWEDB5CEB500000t,0*46",
     "\\p:spire,s:terrestrial,c:1692781259*55\\!AIVDM,1,1,,B,16K3J3@0009`3>lCm0O9WbCP0>`<,0*77",
     "\\p:spire,g:1-2-7337124,s:terrestrial,c:1692781258*11\\!AIVDM,2,1,4,B,55BPGR02A<po<HHk>21`DIU8u>2222222222221IBPS<D5lA5<Ai0CTjp43k,0*7D",
     "\\p:spire,g:2-2-7337124*6A\\!AIVDM,2,2,4,B,0CQ88888880,2*39",
     "\\p:spire,g:1-2-7337125,s:terrestrial,c:1692781258*10\\!AIVDM,2,1,5,B,548bmt01iETdiW??760M9Dl4qB2222222222221@8P?3;5<P0?Rk0BD1A0H8,0*5F",
     "\\p:spire,g:2-2-7337125*6B\\!AIVDM,2,2,5,B,88888888880,2*22",
     "\\p:orbcomm,g:1-3-8368053,s:terrestrial,c:1692784374*1E\\!AIVDM,3,1,3,A,8h30ot1?0@6;`=D9e2B94oCPH54M`Owwqpwwj`9M@P2;`@D9e2B94oCPH54M,0*18",
     "\\p:orbcomm,g:2-3-8368053*6F\\!AIVDM,3,2,3,A,`OwwqJwwj`9M@P2;`CPPP121IoCol54cd0EwsLwwja8owP2;`DD9e2B94oCP,0*34",
     "\\p:orbcomm,g:3-3-8368053*6E\\!AIVDM,3,3,3,A,H54M`Owwqpwwj`9M@P0,2*63"
    ]

  def messages() do
    @messages
  end
end
