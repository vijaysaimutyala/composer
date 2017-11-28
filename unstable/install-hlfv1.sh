ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.16.0
docker tag hyperledger/composer-playground:0.16.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� WZZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T��$q����cB��{�#��- 9�j��x��P�"��Lc�	kc#��)��d �1am����@�@�{���0�fjm��i�~Y:RȊ�C��vL˱=� �����m�k����i�h������9�2�>(6.�{���m�%B�,M	��"��GC��y�ǥk��P�y!��_�%���]�)�����w�T�gdiV�n�˃��t}��@�_�����Ea9�/���iF��&c��� ��>�J?T�"s-�~���;����R*�{wɂg,��G���[�nBYx�,g�/
��?�}ҝ�T�9i�������0E�A d�j[3R��o����%\������0E�;Piaw>|j�ƽ��?��?<����?&
�R� ,�qv�W�N��M"��p�KU��XZ��sv��A(�48& -뀝Ѧ�LJ��������nv��p��i;��ZdO��۱�.^�0u�rM���������:����9�Nr-��4�coF"8���َLݣrLS�ä<.~IA�i��X�)��'��)Ȱ)okM��0�e�P�gZ����x"����R�P3)����Am"�;J�kd{Tݚ��jZJS�"�V��; "uMG ��I�j<�n�4� CE��� M�I(�)N���4$5�8׼,>,��d���s9�2��!��������?�������.��O�����/��E@��c� b偺k(dN:���:��
,�6�'"`����ѡ��َ�y���`�~k��J��� �����bM�؂�a�,x���4����	�]̏І��U>, ?
/A؈��:9*�8P9)e��a��8s�.\˽D*9`�VP� T'|/I+f�h[���� ڠ�0�a�y(��FB��?���l��r7	��{�x=&��t>Pw`�yj�8�*3mU'cd�>>c}�<�݉dz�6H�}}ta
�8f0��Kr;VH��'�䊮��BDv��_�N7�����[쁎����t�8��Ԕ&0�e^���[O��?�؈�[����,a�>c|B}h�6���_���ᝨ���?�`��3�N/ �a�����q���k�WP�0:�?�PaT�@˥�k�)�?H���K����1)]��������S�ԗ��c������[��,<;)=ڇ�3oӁ��L��5f�:�cwۂ5�Fs-���6~L�Ϥs����M��N����*�*[��	��8�W߰+�����E �r��Dm��96r�r��K�?̔ʹ���ˑ��ۼc@��k��Y�6���	��^��,�?#�K`���g#�F����'��:���%��Uy��Ty_��3����R��M����S��R�gW�0Vz���:��B[kzÅ��,����:��֟�����w`�P��ZQ7A[�n��,��QxA�R����MfTt�A��fŃ�K6��p�6Z���E�W��]{�7��,��)γ̲��ؕ�.��� �o�Q���oa���S��bu�B��TP��6�ra^
s �޸����E��HA���r�����Q�����Qa��������ǚ}O�Nh�]����,��P@i_z�s���0���q���8��ߋ���O]��F�����d��EEb�����E�m��K���xt���Fc��!0q��!n�i`'ܲ�,˴�A���?m����a���!�%�=r�Y�G!�\1r)����K��P�כ����O�ɖ��C��(��g�d���}�Am@������oD/�Q�W���tp+��)�r�w����2��8��M�$H�A��BV�9%�Z��cS�zM�2z��Rq�jP�#?��"�T;V�����3g2x���]���^�a���4cir����<�Bf��qq2�;�������e��̚��\?Dāo.�4|t�Y9>��03"��q���� dm� ć��8_�w�V�ѽK�¾�%2]���Ɗ������y.�������(HK�o!0[�}U��>o��	6S�����p/ϬL8�xn �s#?�$�"9>kb�Ge��è����0;�7 {-ʆ����tU�����GQ�kޓ������ �@�]��k�lZVT��թ��6��&f���5���~����D1Ȧj{���O�Hs�>�Z�g�`]c�D<9��ܬ	�h���醳1I*	�k��XkL@6L�	0|B�w�����|�0���3��g�Kq�b���*a������u}<�,џG��.�0@୎��P��i��f��8\R�w>�x����eDv}$�æ�����;:"�6{��"KŘ0~ �0��B\�"UK{�5��6,��X�n(e���k��!��X�ܫ;����t�`Р�/�]Bb�6H�1�v'�&�����a�hmd�Ήrs��~f��R�P�d��f���xVx��w�84u�!m�iBC;�4,22���&]i~�����*ۤ��!�q(��9%��6�	TW�چ��("�J*䔨�)�߈�D��C���(���-&�)U"��5�+�!�Hf���4(`4	���x!��_���@��َ�U����)��:��zu�k.�# ���F���P�f�-���;D�F�gB�0�eB2�M�f����KO�z� �i�z�RJxY�s52|�He��}�|�~�m��y�Bg��8�%Rt��->����lR۲�5���zp��c��.S6���|�S�����
�y�+6��b\X��Z̫���e7<��T���p����S� �[�G������A��f�-,.�����(�) A��-D�,,trU~ծ�~����u�V��%���׸Kt�+F1��X�c�C���V�?F�7"��Y�u7��.v`�����:�z��p��.�������2�cp��Mb��v�f� |��_8)>y�'I�e��B���o��̻����������5���O��h�SDQHl�^����ꢲ�H�굄 
q�D�11QKDE�	)��k�I�mH��|���[f�����/��ɝ�Nv��!�¬|��Y�V}��0)ӰM�����W��Y�`����뛕�|3N�߿���e~O�t�^���~��~�W���q����Ϋe����c���Ä N	�h� ��0������쟺�=���S�N<�>�G��������ކǌ�_�����-��E���c��e׉���8m�i�����E�S�uֱ��A��_,�E�����2��ÙLe7/Xr���u|�>F����І�.��!$&"��l�
��O䲹�\��ԷF>�Km��R��jȽ\Rn�Jr��7��j$��7_�53�ҋ�T�8�k���O���)�=LAnm�|5�l�S����̹\J6
��T%�*4k�z�}�£�Y�T�zyJ%}����[Cig�cA??6ζ+�kìd����{�٬�N�'e�&pg;iz8�JF(4�{������R�W�^�4'�+9n���H�)M�io���d-_�{��q��X���^V�3�<n8R�T2�[�6<:�*m�s\��E��g��[�*d�\�|$��ׅ��y��OrC����G%I2n#_�t��u��3}�]��*�ܒ��v��a��r#��J��{�����mwc�,Y�[g�J��������ݣSɉ�q;�*��;�^��0����c�+�f�Z�4)?��tz�B9����A)v"f�ۍ��i�����"�,���e��^���N#-�I[��I����Oe9��I��\��ʧv�\�m�@7��%o������?t�Xrp��R�X^^I;x��y���`J�r>SM�)��-���L�C�r��x�����q�<��I�lU{��nJ�4r���3ۅW}�̚���z�D�-�5^�w ��Sb"�UՒ��֠C>SHOQ���2	G~�3�ƞf�h�	��t����k�4fp<�����@��`��Lӹ	oV�
���;w�ȣ?uݗ������G'��<���[�$?t�f�i�c&����k�|����z��P�b��r���䮩EZ�{̜�ˇ\��
�G��ճi���v���6�ɕ���M��j���W[�Y��???�)�|^C�ǌxت��%�/eu$Uw�m��jU�t+��"G�U���ީp������O=f�+�Պ}�V�|`^�/L��<f�?/
���HH�R� 7�I̼n3�����$1��H̼.3����� 1��G̼�3�w���1�|#�Z����|��x������"���n�SW}	�>�O���-������^.t���^�w���u)�8���rQIr�{V&���J�U���Fl�jt�A;��1��'�|+��t��=̖MӔ������:w�m�=~��zg\b�c4*9��[[AnR�O�j���܊	��-�=C�cW�K���O@���-�K��/����I�A	�q���'$�� �:���&���5dm���o0F�`j���o5l�@�5C��f�D���e�64`�\���V�a���)R@�R��%N���v��G H�m�� _K��7�Ȗ;H��XF�^�"�jH7{4�L5��Z�S$e�2��v�w��c��򠾷�$��A��@����Ao�����=|�~� �,�=
�Iu<|�2`M���H���`	!�N�3���Z>=o�v-:�� �1�7UA�<���0e��
����i�G��C�M  -�	C���r,٘v���>�m�{��� /���ۓ	��i	}p5�^<�&�~�V��������� �n3�����}:e@���,P^1ǯ��>lA�<���+�C��@ʦ
�~�>ip��κ�;�8�ͱ�؋���a��ɗ��D�w��ȵ6��m�.� }�.��yH�<$�JX�|���Bv��.���ځ�v��릉Ӵ��)z�8�;^U�=�q�8����qй��U�<���{�G��ff���v�·�]��[��̴ӟb[�Lg�N�����Pʟ�YN;]δӶ4�9 �]i�4�7$���pY�sA8 �8CD��i���5]5#M�h��"#^��/"^����:WAn�%���%Y�����9�P�����Y��/�&!!i��s
���G��T����z�b.}����Ӳ��1Լ�:��Zd<9k6v��u�~�5]�^z��a�$�?@�>�����+F��ƪ��?h¿?����If{�+ kr�3�s`�H�`�?|�A�Pv���!��A�F3g'0Ŝـ� �Ɓ&X�e���|��E���K�>�t��˲��.pt �%�9T`���C�W,�4�{���ýe���� �Ӿ��aƚd w�!g�~�2}�1(��͑S�F��n
�?����~��c �%UEvݚ�P��p��M�����Hh�1
bza���d�����(���ǭ$��<Q�,��?���o�K�/ߝ�u�o�d�����ϧ��������k�$�	���Ė�o�{���r�'�ȫ��r1i�}/�Jd�&R2��Si�L�dZVdVK�)B&�Y:�d)Z�3*IQt_�d)5~�)9� ��w~�>}��g~����~�ɟ-�����$�{�}"�;D���^]���c�f��o�z`��7b?z��o<������f-���c�ݏ��}�g}���߿�h�k�:��F�5x�+��A&��s�R����I�e9������Z��9�]��c�w���1�;�U���wƼ"��w��[]��a�2Z�%�C�'݅xR�œ��^^=��Ģ�ȭ��w��m1�aKl�.�M��	��,&�Qv)�́��y}+�.�CH�qi �*������ͻ���`���Eyt��vHW.�g]*��-����I�I�.x��jlX��T��2á�'�JKv��O�r��{��N���\9����&�mj����Fqo(c�U>_�7�Sw��(H�J_�.�� jL�g��za$2t%^�#2�����˹�p�+�vx��b&�N�����$�<Mۼ^�~�bN���+���J��u��Z���a09Mn_p ��zn9=�����J�.:�"�1�՞Qn��{�$��U���3='�L�M��y��vLa�a�9ժ.���@�h-���̡݌_pw��.��;��;����Q	�u��f��b���t��J��bg/;���E6��ɊLU*=�l��˳b��B��bG-,V�=�G�`0S,v�-z0({�'z2n4�A��/z�\�����s4�j�٘hҥYb�R�YI8F��i����9�V�S����R6%��#���J��R��pM5[;���5q-�O�S��,�?�"~�=����l���l���WGU�6�ŪĜ�\RI�B�M������l��f|>���Q��i�j�m�͏�=k,�Sʐ�0'0G�43��JqHi|�zph�ڽvu��0��sR���F�Lj�_@e��x�����/�{1�V�^���K�^x�*|��kab����5�w�W������/7��S�e�2�~�{_����୸_.����}H�}x���c�{�//�^��v�j�?|�e�~�V�߾�E.�b?��?���?���������̿����W����Z�Nf^m�[c;�
�n�ԾrF�K��-���d~�ڦ{��{���]�<�\�u�fπsa�њ���XW��u�u��6>�v�����F5�(��bu��"˺���0�f�ή�|1=K�R�=nR��'u,��%;�5;"+�!���1"j=�`����H�{Rp�E/�ؙ~gu4ʗtC��-2�bG-��q���H,K݀#�`9]V���w�cjQ}�m1���b���u�ͱ�̯F��u�i�{�ýtڑ
�)�@�%��7�A���s�mJ�Rd8�g�8Җ��QA&[��htH-�(�U����ۣa�U0���\5'�]��d|���A���z�q�#���qE�f|�҃�E���ߺ�hrPQ�CE��-��=���r�ϔ��>4Vg�������
��/o+��s(�ܨ2�#R�<�Z|B���	��p�eŴ@���qa�{xrǮK��cH�?a�~�����sV/\M�c�-䪔X���mt�5g�Kf�\���5����x��*��ްc������$�6ʚ�s�^���ӺPc�#w2��*L��=�TD��!�5Fd\OQ�=E9'2�{��	�������B�-�^K
z����f���N��NTt�bۧ¡�+��3��	 6��فr��i�ޡV*v���:�K����������Ӟ��F�ε��B��抆����2^����a� 	����V���?y&���.��J
��Z�����>�Hfٲ:���ĕ��$�[`|A�����]�F,�H�`�=�	�	�փ/&؎¤��@�`�=���Y'��C� 7ٳSf��c5�����/�	���~���{���S�j�5!%��6��8�:e��2�m�pPH���ln`��`
%�u
H�%�.w[��=�~:^��F6�[�K�x�N�h�B��PJ����
K�F3Òz�D��Ō����k1GG�E�����I�i5���5�q�u��.1�F�+���S_=>�%�e��S:�f�3��E�ꥉ�^�A��@|�K�{-�����Po�z��Ze�r�P�쾯�64ۙޭX�^P���b?Os��=�[ˉ{=�
��m�VX�!�s��(����bo�^������S���O�̷��P���(/�����K�ڳ�G�7Xx�q(�����<^���M�R�D�<���^��1�S� ������2�q>�~���ɯ�DW��)��{��7�����8��N5���{����>E�ґG�s�"_Ȭ��^���K�']���9�����t���J������w���n��J�w�sB���z��������oX�^Nmd�!k����� ��� ����TJ��4�F��܅[~ �u��Y&l�y�����a�a�4���k��V�v�0}����G�γ��7
l��ج��y�h}�~�\�nV9{�z�%-�����!HO�������v�b�;�&����:zSH��L��7��x+j	����!�G��%�cA�G�b�!h ��� j�=Sh1�F��T�&P}k��@�g�o�ؤ14F|�B!/T�t�ゃ�kf��X2
v��D��̛/y�< :_[�!�*�0�X�y��oI�����.�at�9��Z��7:�<h�zR����z�iM��6�Sk�l����E�	d]0R#�
g1b�'��^�B�P��3��m+bM^�ω�����찑�	�y����P:V��H4��X9�Z'�!	̀ʸ�}O�k& u���+�D2�� ����l��:��\N�_�����d����Sa]}�Q��2������}'�ic����6�x�0�(ͯ!�$S˶���bLP؂�����}@�N�6YOå�ƾE�V�2������-Ȍ��CC���4ςx��8cؼ%pj���>�oN��P���]*k|;s�Fa$��q��mɫfM��	C���5�LdٺV�nF�x�R��C��
?���g�Ah��A*�����8���K��=� 5=C���\�!��}8��C�3;���Z�E���-����m���S�?���+���'b: �ӕ'�0����p�Ep�g!�8eoB�)P�;S˴���G��(@4��(� Z�5pcC�H\��FmfG���F� `'�t��g#�G�MZ��#d"�#�y���e��do�����ʰ�pb���u�B^�M��R�]\w����M�����\d���!�>l���$�����3A6P��0����ƃV#A�~�� * �� �����#�zBh���9�t�i��ZC(@�Q�;0tT����p"��2�#�*���"r
�}7nl9��I���&��c�G�g�,����y�jtт��nAN�1M��P:���<|����8�:�Xs\k:��Ʀ��ܙ��ȱ�RDpގ8����v�oj��c������3���qvi������v�g:�Jܝ��F�C���S�cDC�1�<^����_! :,���Y��!�s�1���$�9J|'8'wTl�C��0 Ď�b�\T^���_�Z��zaC|��ڑ(J��	:%S�$��,�ItBK��T��(Z�T�}R�(9��R�ܗ�ٔ�Lf4�JI0�-�0(�"���[^�-���rZ� r}�?�Ƌ?9�ɣv���ر �y0����@�YINђ,�D2C�UI%)-�RV��T*���D&�����BR�d&�%�)�$L�H������z��@oi��z���)����K���<�����bPp׾`g�/�X���ȶ�����_�L��\-��C��D��~~1���+�5�f�	��+����ߦ��V��=AG���M^���9�.T�)�͚�=��]VF:<��ٟ`t�A@yvd�*<��['�[�\-nO��n8���p��Zmm�b��-��o܁�j�E�`�6�=�]&0���mu{�@�Hv���)�<�t5|�U<D�P)�x�����{���\�[��h���va��x�W�ZU������b?��w��4�Ogc_�zlG�Մ�����(Z6��sf-m����@�b���U+y�p\�[�j�@�{��q���f���H�-r=�5�U<K3��!����
�n�C����bX��?�Y3e����U۹"��c��
&H��Uy��f�ϕ@C�-��9���Co&��%���!ars�`�It�<��h�>?�_A���nd�M�[�|�v���l}B�Um��U�x}1��-��dFv��~���M b��l�8Ŀ5�`G{�n�AہSa��H�GEǰ�϶u�|�߮n�-�W�&���_��>�����m<��'
���[��O�}������J%���6җ��7M���M�����t��"]'l�]��t���������/��Hb��������t[��<�J�����l�-�Q�/z����;�﷒�<��y���@�\=�|�$�L�K���;�����nK��Ԭv�}���tF%�H��*������MgHEKe�L?�$�tBN'3�L���$�ؾ)��j�/��?�"�����_��޵5'�v�{~�wo�p>]�U/'�|�����(��դ3=�:�t�tg��T*�Ŭg���^O%����������X���6��i���i�����n��z��Y������Q�3���gv�tg'z�!��1F��6�x����I��������lu�ƣ�2�Jc���ԋ��r�&�?���k���&����ׇ����ِ�_'�1�x����q��*��'��?	�_�������z �����w�}�����Q3��&��~>5����k����@�W����*�m\����_;���=�3��U�Y���#�_��U����Rs����� \�	Wu�U������0�	����/���P�n������?��+B���Ck@�����!���V����?����)�����V���nHg+���?�Z�?]L_�?���'�#����!zW���m�y��gQt�of�����ϗ�Odm83en��Zj��.�f��/�>�).��~��4�̍��Ȼ$K�\hz�d�m�}dY�������)������{}��e����ώ�'{6S�.�+G[�{����b�R��T��?ۮ�ݞ�ǽO�rX����ř�Dz��y.��V�w�C+�QR6�Y�����v�I�Ќw�XN>:[N8�|����ASw�� �B�ƙ��n�A#���kC��ӂ(X � ��ϭ��������H������?�p�w%��'���'�������U��/�#��P�n����l���i��*�(��CP� �P���}xu�߾������>����!4�L�!��o��og?���\�)�w2���?���k�����ؖ2��'�d1�=����mT!<���X��1�����
���jT�R���vߝ0j0���v���dOe=���>t�x��� I�B{.�W�dj*���������Ʒ��pd�KA�b�[�F�}Z����4�Ζk}�D���b�ba`�I�8^x��1w}b�ˏ[j�l���K��ӱ>�3�?0�C#��@����@��:�dyz���P�n���'��,<�A��4���g������4G�Gc4��!R>�A�ɐ��0M򤏅���h�?���������������m��diƝ%�m�E��O��ߑ����7��'j�<���8�]^ќ��;�Ү�̖}������)ئ�͖�����Q)�,;�!6����ߡu��vtV�y��ߊ&����Yj>������	�?�����?�������q-�~3>!���P�Շ�Y�S����:m'Y��-a�3κP���uWm�Yz|���>���ј��K������xd�.�EaŁ$�]
[G�(�H����j]�B�.�-ۚl
�Ȃ��TL�P�wi��ފf����5����~���W@�`��>����������^�4`h��c�;�GР���k��-��/b���#*�H�7S��q%Vγ��������R�������������<}�� @��g�p��Ag�+�REn� �z�`�)5r4m����tK���{X �V�^���ەeɣ�TD+2F�>�Me�bi����A:�{Uo�a��v��ܠ@"�|��&ї�p��{z��� �i��.^끃)m�*>a���'t�(�F�4e������r�D*��i2�r�L����\�bKjo�ĝ���GMH�8}����AWLIU����6�͏�2[����x����I��~?�v�j�bq�hh��"����T�R�|�O�":��N.k���B����p���@�U��?�&<��*��k�?�~��f1���M��듿����%���!ӯ�����3��f	��� ��C�?��C���O8��ׄJ��{>C{��c��so�!`�y�P|�bÅ���o�Ax$A�9>���/���C���O�迏�Ϝ�u�q]�;��m��M t�� �e����~L���S�I�_����Ow�2�XVI��t�v\��r�V1B�R��Mq�0BY����2f0���U����������Sn�>0rӆ�߷�	�?N=����J����x��U�	U<�w��A��_��̝������2ޛ������ ��?�����p���n�����'q��������o }��6����h]�ع�S6N�ub��e-�߲��+��D~d���=�Gf�o�l�_g��bbNF�7��ǝj�E^���9�,�xg}�l}��O�1�g�dE猼D&#�'v���d�&#g1�4Ak{s+�i�uYwWȜa�j�χ#ƥ�K'*��m�}]�:ȭ�+?g�ߞm7��0�-n�wdEU�è�.��~���@��&�=&zt����Tv$�#��De�� ��}{R�W��G�[���*ZۉS���4G#5�h�I7F�2O۩����y�h!ӱ�zX|�(�=�g$4z,�24A�]���[��p�{S����M�'!��&T��0�44��0����W	`��a�濡�����_�d`4P�n�����}������)hD�� ��`���������������c����ǟ����K�~��Ǩ�����'���M������
T������X�������?��]j���������?�`��%h �C8D� ����������G%h�C8Dը���7�����J ��� ��������a��"4@��fH����s�F�?}7��_���R�P�?� !��@��?@��?@��_M��!j���[�5����_���Q5Q�?� !��@��?@��?�[�?���X	���8���� ������������������M��a��>��?�����/]�������W����%��C����s�&�?��g��M���AY�_`ˑ���pP>�A�W�`���$�α����E���g�	�}��'�����8R��
��4e�R�w�׊S��
T�`�w�L3�0���E-�Q>^���1f����L�䔴�0(G��%�ˑ`H�0:���t��Nw�eۓ�V9�6R���0B��ڹ�#�B���v�]�G�r�u��h������/wm,܄��Lu�kiw���~��&����Yj>������	�?�����?�������q-�~3>!���P�Շ�Y�R�ϭ|`��V�!y����j8/G���Ƈ��"씭�����un��(Qjв��a����(���C���S������ufG�?�:�r�;w��p���I�а�HM=���j�Th꿷��������V�����Gp���_M������ �_���_����z�Ѐu�����������xM����:�?���Ii"��55�Չ#����_;����Y�ݤ�,����w���Dޒ�G���a���%�������l�GX�����'�������Nx�Ml�Q-EڊY	e�����%�G̎*�����L�r��&їw�����������B����)m��'�yuY`@xB��ahtNcQ�9���P,7��q�1�� 3(G��AWLI��g��󲾼�?��d����COcds�݅u<�N�jB,���ķ|�KU|���5�"�v�)�
�{r�.�;�ݛ��}w~����<<|{|�o|�cq��V��x��^���ϟ�	x���	�N=�����J���O�n0��XT�����)'���@������/�_����\O��h�����`����+'��W^��[����k��n�6�n;�٣��b��H��W�����h˂���!�6KӢ����_��+M�����w�'�y�/����3%���-�o�KO��rt�.o��-��kl��l1
�8����u�E���Y�-i:�@�v��I���i-�l��t��N�2a1!��kZjD(e���^"���@i1���8N:^vȤ䎧���!Źbj��-�d�=�o�쥝�\k!F3��� ��y�a��-�����gb.Gf,J"��g��l��~[^���maF��5��*$΁|@��w�o\���
���H,��ŉxD�h�?qz>��-L��y(�6�t��V+R#1vPO,��;z��E望%�*�L%�u�	o�d���������?��V�j��Ә�����_��]�M1������,K���#Y�	� }�B,����QhB�?���a�������B�͏�0�Cw~�����[���g����KW����˕���=r�V`���������������U�&�?�%�������p��*����s?�G���������y_�?5�N;�š8�
;�2�Ep��yv��_P���)����6�}����q?�G�������������^|��y��g�qnuM���]��HL�%�a{e"<3�&'m�opc��T�m�l���2`i�A���٥��[L��݋bu��l?佾ߋ�<��<_)7�(�Q,8�NK�X6�:�^P��E���t9�ٺ4��'���N;>n/��f�cv8e��tp-Q"��Q3۬�"@��o��A��2S^��R܆K*	[�i۟�����X�ᢲ�������	��x4����������
B��p�\pq����+�Å���k�ܛ���4�?���I�:S���\tj�T���ej*/������}�mӝhv:�i;���$F�Yϻ�zߥZI+��#��A�I��3D�\�ο7$�������������=?��O�2kO&̆Dk�C�����\����x%j"�90�Qu����n[ׂ��m�������R����X��i����k����K�4�-���3	�?�?j���_�HY��e `8(3���8��_��,	�*|k�GH�?���LԂ�֝Ʈ^K�V`������O��0h�ʥ�C��u�7���XY7�"
ا"�W�b�Q���ج,���&~N9?W��\4\������CW��+�q��7y:��8���h��ȯ+ᅽ��pR���,������j���D���pZ�n�l�����<st��
�u3�F���LЌ��(m�-9�bY�69�7�6�1�Q���\t^�Q<��(48.���}�Љ�g�և��;mJ���ao��]�ͷ5[P����`�mAVW��z��e�5�]��ڦ<�ju��f���ؽ��EK���v���n��9�]�S%�*[K��("�Y�{�B�W�K'p�/t�MI=����4Y�ĭ��a�O*����Y����Y�X�	i�?L�������E��N��	�?a�'�����o��?�C@&�����_���ё��C!��������[���*@�7���ߠ������y�/�g	|�4����)��tȄ��W�ߡ�gJ���W���E����������_��MT����>w ��������X�)%P�?ԅ@�?�?r��n��B���AF��B "-���������T��P��?�/�����_��H���B���}��L�����H�,�?d��#��U�
��� ������0��/m�u!���}��L�?��###�u!������C���*@��� �������`�'P����a�?b ��o��	��n���_��������D������a�?���_2��p����-�cn|�t@���/�_$��X�!%2��C���%vFkF�"Yf�[eҤK�Y�m�l�$�1,K/k��2�2���?o����ɂ�������Ë���U�qX����K�/W9[�|C�[�נ���eAxz�U^�#-��tl�9�M��)���&�/5�ny5�-k��k���x�!̻\2\�o�V�I�Gu2ȓy~;(���Z1\bM����/0]M�{+Zo�:m[C�pyy�Ǯ��8�$XG��ꗗx�S��x��P_�������U��`�7d����Y���������8D}�,�?�������R�I�69*�y��Z>*�?������vJ��=�]⿚8\�f�V���ŷ�zM��k�(�X8��~U,I��mV�Fa[�3U�%zq��l�PG�6#��o�B���]�ג������@��ڃ����/D&�A�2 �� ��������Ʉ���k�W��߬����Z���մC_�{�u��БE��ڿ���&?��=b����Lx������/;۰��m�p|c�uh�[�ix�ͫ��HӇ����l�'��؊F�-��;�7^9�dq�n�p�Kn+m���������o�bm�W�m�����<�?�*%lS�f�^�7�_���(���Mx�3�&�{�{��s�Ŧ���on�j�s�Wz���{�����I�#rw:5���DG6���*��*�s�^W&\T?�ä��H�c>"��ϋ�8�Fi@ZCJ�w��Z��k��A��_��$�����*޺�zL��(i|���ï�٤���=���F������Ӄ�5��M@�?�?j�������?������9�����������?��\�_,��Z�#��������1����B���@�OZ��}�c��`�G@�G����L�?�F�/��T@��`H�@���/��? #3��?"!�?s���C�G*|3���h��JXڷ��÷�ѱ)��13������n��I�����~��H+���]>�~$���܏$�{E���.���K��{{]�o�脽j�?R��1��+^۔�̴�Ѿ6+��fk�+���w�x{����	k�4O��Ôₒ5:�גj;����_�G�~/i�؍�_MOk��
��,9/�,j�f�)��X�H��|�)�剫a��~9gl������`�x���r�����z������j�^zk��A�b�9�sje�{�>R*U0�ƪW��
;_�O�A&���#��{�8�kq�@���/����Ȓ�?>�^�T�D������ ��������_h�
����=/��R�%�߷�˄��8�?"2��7^ oM&�����o���J2��E�Gu;�Ԫ��;�\�M��~�������Q$ۗ���XwW�zx��)�Q ���O9 �}�����O�ݚF�k%���ݨ��zE�4��Bg�=3(`J�ߔ��Q��y�8�HC:T�L��
=cQV����z �$�� ,I���n�E]N�G�U~^=�C(ܾ.fsSf\�m�a@��RP޻�=^�;���Ayݔ{���Cs{Mi/��<
HSg��n��N3���/��0��č�_��W* ��G}%������eA��č��E��4Ȏ�Se�5�"kY�fh�fΊ�NZ4�3�NФE�x�l҄a��[m�:˘�K��c�V��_�,����?a�:���?���9�[�듩Ǟ�����DS#�n/O�-�ZJ�$,�/���͘,��v��|M�#��
��^�V����h��EMk��3�9�2�8�j�d�4U�h,Z��1q |l�N8��?_K��������p�d�������������`��wI��?t�����V��B�۲�f8V),)m���n�Y�&ٙ<>r����1=�Ho�-�y^���w.�*Q��h��=qH���իd�0;6�ӮX�=�[�nP.Kt��&���hX�K����l��W��d���o����``�db��!� �� ���������,�?�.��Cķ��(������s�cF�m�<���-�^M����������~, �,�2 ������p�i���^^����;�v�n,�9,7��>��e�h,�%6<2Lo����bK͗։��5�T�J����ů�<}n����U;O>�<W�Mx�3�rQ�'�\g �QC�2_ ��0`�ԼRIvÁ��DE��em�a0�Z�Ux<��󛻼�F��?��t�����HO��m�g��}Q8�'���ť��U��Ɇ��;w�J��ʞ�V��D�����%�F�>g��h/ֆ�:�kթݙ&T�(N��_�0~���7Q��w�j�^�fC�q*���?I1E�?�͹m�����k����Ը���yc�p�ֱ����$��*�GA�?��~����Q;�.<$�����Y�9���:[9���	r6��ۅ�jc,s�~_���=���{�뚫ˮߌ������N���/6wy�Tr��O�d�}c^{�'wI(=ny�����#�y���y�d������o�Q���k����N�۸9��0g����g��7�i�UrǬ5w<`��>���=34�xs|9ɣ�ob\W�������c9Y�+ٳ�kz.��9c��f����ǯ��G��t{��9c�K��7<�����\����t�����]�?��������G�^��'�O���b�H���]��`%{����������<׫�m��v��rfɉFZ|	����=�_�3��s�;'nr�7R�2�5�x��|��\4�5�߹��ڹU�d����Ϝ;3�����\����4�֠���4?�$w��M�0Әor��}뵿c��4��n�����I���i�<���o/��ǧ/���]|��n�����4k��\�����+\�[z���qܯR|�_���gg�!��	����-�ݏ�^[h5%E~lϮ"�U��>��)���{ՅY$��A��ԟZ<Ԃ                 �_���,2� � 