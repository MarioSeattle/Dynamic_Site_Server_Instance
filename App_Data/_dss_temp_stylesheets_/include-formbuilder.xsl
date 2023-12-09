<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	xmlns:igxlib="urn:igxlibns"
	xmlns:formlib="urn:formlibns"
	exclude-result-prefixes="msxsl igxlib formlib"
	version="1.0">

	<!-- Custom XLST Extension Fuctions -->
	<msxsl:script language="JavaScript" implements-prefix="formlib">
		<![CDATA[
			function removeQS(str) {
				if (str.indexOf('?') != -1)
					return str.substring(0, str.indexOf('?'));
				return str;
				
			}
			
			function trim(str)
			{
				//Remove leading and trailing whitespace
				return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
			}
			
			function getValidName(str) {
				//used to ensure that form and element names are valid.  Remove anything except upper and lowercase letters & numbers.
				return str.replace(/[^a-zA-Z0-9-_]/g, '');
			}
			
			function getXMLValue(rootNodeSet, path) {
				var rootNode = rootNodeSet.item(0);
				if (rootNode != null)
					return rootNode.selectNodes(path);
				return rootNodeSet;
			}
			
			function SplitString(input, delimiter)
		    {
		        var s = '<strings>';
		        var strings = input.toString().split(delimiter);
		        for(var i = 0 ; i < strings.length; i++)
		        {
		            s = s + '<string>' + strings[i] + '</string>';
		        }
		        s = s + '</strings>';
		        
		        var xmlDoc = new ActiveXObject( "MSXML2.DOMDocument.6.0" );
		        xmlDoc.loadXML(s);
		        return xmlDoc.documentElement.selectNodes( "/" );
		    }
		    
		    function manageValue(value, rootNode) {
		    	value = value.replace(/js:now/g, today());
		    	value = value.replace(/js:date/g, date());
		    	value = value.replace(/js:time/g, time());
		    	value = value.replace(/js:ampm/g, ampm());
		    	
				var regex = /({[^{}]+})/;
				var matches = regex.exec(value);
				
				while (matches != null && matches.length > 0) 
				{
					for (var i = 1; i< matches.length; i++) {
						var match = matches[i];
						//for each match, get the xpath
						var xpath = match.substring(1, match.length - 1);
						
						var xmlNode = getXMLValue(rootNode, xpath);
						var xmlValue = (xmlNode != null && xmlNode.length > 0) ? xmlNode.item(0).text : "";
						value = value.replace(match, xmlValue); 
					}
					var matches = regex.exec(value);
				}
		    	return value;
		    }
		    
		    function today() {
		    	return date() + " " + time() + " " + ampm();
		    }
		    
		    function date() {
	    		var date = new Date();
	    		return (date.getMonth() + 1) + "/" + date.getDate() + "/" + date.getFullYear();
		    }
		    
		    function time() {
		    	var time = new Date();
				return (time.getHours() % 12 + 1) + ":" + pad(time.getMinutes());
		    }
		    
			function pad(number)	
			{
				return (number < 10) ? "0" + number : number;
			}
			
		    function ampm() {
		    	var time = new Date();
				return (time.getHours() > 12) ? "pm" : "am";
		    }
		]]>
	</msxsl:script>

	<xsl:variable name="postGet" select="/*/IGX_Info/GET | /*/IGX_Info/POST"/>
  
	<xsl:template name="initForm">
		<xsl:param name="includeJquery" select="true()"/>
		<xsl:param name="includeCSS" select="true()"/>
		<xsl:param name="forms" select="//FormBuilder_Form"/>
		<xsl:variable name="recaptcha" select="$forms//FormField_Captcha"/>
		<xsl:if test="$forms">
			<!-- basic jquery - include unless it's included elsewhere -->
			<xsl:if test="$includeJquery">
				<script type="text/javascript" src="prebuilt/visual_form/jquery/jquery-2.1.4.min.js"></script>
			</xsl:if>

			<!-- custom jquery for forms - always include -->
			<script type="text/javascript" src="prebuilt/visual_form/jquery/jquery.validate.js"></script>
			<script src="prebuilt/visual_form/jquery/jquery.metadata.js" type="text/javascript"></script>
			<script src="prebuilt/visual_form/jquery/jquery.form.js" type="text/javascript"></script>
			<xsl:if test="$recaptcha">
				<script type="text/javascript" src="http://www.google.com/recaptcha/api/js/recaptcha_ajax.js"></script>
			</xsl:if>

			<!-- css for forms -->
			<xsl:if test="$includeCSS">
				<link rel="stylesheet" href="prebuilt/visual_form/form.css"/>
			</xsl:if>

			<!-- custom form functions -->
			<script src="prebuilt/visual_form/form.js" type="text/javascript"></script>
			<script type="text/javascript">
				<xsl:comment>
          j = jQuery.noConflict();
					j(document).ready(function(){
					//on page load, hide all the custom error divs.
					j("label.error").hide();
					<xsl:for-each select="$forms[AJAXRequest = 'true']">
						setupForm('<xsl:value-of select="formlib:getValidName(string(name))"/>', '<xsl:value-of select=".//FormBuilder_Captcha/RecaptchaID"/>');
					</xsl:for-each>
					<xsl:for-each select="$forms[not(AJAXRequest = 'true')]">
						j("#<xsl:value-of select="formlib:getValidName(string(name))"/>").validate();
					</xsl:for-each>
					<xsl:for-each select="$recaptcha">
						createRecaptcha("<xsl:value-of select="Key"/>", "<xsl:value-of select="formlib:getValidName(string(@COMPUID))"/>");
					</xsl:for-each>
					});
					//
				</xsl:comment>
			</script>
		</xsl:if>
	</xsl:template>

	<xsl:template match="FormBuilder_Form" mode="form">
    <xsl:variable name="formName" select="formlib:getValidName(string(name))"/>
		<form class="{FormClass} {labelPosition} formBuilder" id="{$formName}" name="{$formName}" method="{method}" action="{actionURL}">
			
      <!-- GATHER AND MAKE VALIDATE SCRIPT HERE -->      
      <xsl:variable name="fields" select="*/*[starts-with(name(), 'FormField')]" />
      <script type="text/javascript">
        <!--Set j as the jquery scope here to not conflict with other loaded jquery versions-->
        j = jQuery.noConflict();
        <xsl:text>j(document).ready(function(){</xsl:text>
        <xsl:text>j("#</xsl:text>
        <!-- Construct the validate() call on the form -->
        <xsl:value-of select="$formName"/>
        <xsl:text>").validate({rules:{</xsl:text>
        <xsl:for-each select="$fields">
          <!-- Build out a rule for each field if it has validators -->
          <xsl:variable name="validationTypes" select="Validations/*[@ValidationName]" />          
          <xsl:value-of select="name" />
          <xsl:text>: {</xsl:text>
            <xsl:if test="count($validationTypes) &gt; 0">
              <xsl:for-each select="$validationTypes">            
              <!-- Add the validators for the field -->
              <xsl:variable name="validationName" select="@ValidationName" />
              <xsl:variable name="min" select="min"/>
              <xsl:variable name="max" select="max"/>
              <xsl:choose>
                <xsl:when test="string($max) and not(string($min))">
                  <xsl:value-of select="concat('max:', $max)"/>
                </xsl:when>
                <xsl:when test="string($min) and not(string($max))">
                  <xsl:value-of select="concat('min:', $min)"/>
                </xsl:when>
                <xsl:when test="string($min) and string($max)">
                  <xsl:value-of select="concat($validationName, ':[', $min, ',', $max, ']')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$validationName"/>
                  <xsl:text>:true</xsl:text>
                </xsl:otherwise>
              </xsl:choose>              
              <xsl:if test="position() != last()">,</xsl:if>
            </xsl:for-each>
            </xsl:if>
          <xsl:text>}</xsl:text>
          <xsl:if test="position() != last()">,</xsl:if>          
        </xsl:for-each>
        <xsl:text>}, messages: {</xsl:text>
        <xsl:for-each select="$fields">
          <xsl:variable name="validationTypes" select="Validations/*[@ValidationName]" />
          <xsl:value-of select="name" />
          <xsl:text>: {</xsl:text>
          <xsl:if test="count($validationTypes) &gt; 0">
            <xsl:apply-templates select="$validationTypes"  mode="errorMessage" />
          </xsl:if>
          <xsl:text>}</xsl:text>
          <xsl:if test="position() != last()">,</xsl:if>          
				</xsl:for-each>
        <xsl:text>}</xsl:text>				
				<xsl:text>});});</xsl:text>
      </script>
      <!--End Validate Script Construction-->
      
      <xsl:if test="string(target) and AJAXRequest = 'false'">
			<xsl:attribute name="target">
				<xsl:value-of select="target"/>
			</xsl:attribute>
			</xsl:if>
			<!-- render hidden item -->
			<xsl:for-each select="HiddenField">
				<input type="hidden" name="{name}" value="{value}"/>
			</xsl:for-each>

			<div id="FormContainer_{../@CIID}">
				<xsl:text>Form Fields Container</xsl:text>
			</div>
			<div id="{formlib:getValidName(string(name))}_messages" style="float:right;clear:both;">&#160;</div>
			<xsl:apply-templates select="FormBuilder_Form" mode="additionalContent" />
		</form>
 </xsl:template>

	<xsl:template match="FormField_Label" mode="form">
		<label class="label">
			<xsl:value-of select="."/>
		</label>
	</xsl:template>

	<xsl:template match="FormField_Checkbox" mode="form">
		<xsl:variable name="name" select="formlib:getValidName(string(name))"/>
		<xsl:variable name="validations" select="Validations/*[@ValidationName]"/>
		<xsl:variable name="class">
			<xsl:value-of select="type"/>
			<xsl:if test="string(className)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="className"/>
			</xsl:if>
		</xsl:variable>
		<span class="inputWrapper">
			<label class="labelForCheckbox">
				<input id="{$name}" name="{$name}" type="checkbox" class="{$class}" >
					<xsl:if test="checked = 'true'">
						<xsl:attribute name="checked">checked</xsl:attribute>
					</xsl:if>
				</input>
				&#160;<xsl:value-of select="label"/>
			</label>
			<xsl:apply-templates select="Validations" mode="errorMessageAnchor" >
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
			<xsl:apply-templates select="Validations" mode="script">
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
		</span>
	</xsl:template>

	<xsl:template match="FormField_Button" mode="form">
		<xsl:variable name="name" select="formlib:getValidName(string(name))"/>
		<xsl:variable name="class">
			<xsl:value-of select="type"/>
			<xsl:if test="string(className)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="className"/>
			</xsl:if>
		</xsl:variable>
		<span class="inputWrapper" style="padding:0 10px 0 5px;">
			<input id="{$name}" name="{$name}" type="{type}" class="{$class}"
						 value="{value}" />
		</span>
	</xsl:template>

	<xsl:template match="FormField_Text" mode="form">
		<xsl:variable name="name" select="formlib:getValidName(string(name))"/>
		<xsl:variable name="class">
			<xsl:value-of select="type"/>
			<xsl:if test="string(className)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="className"/>
			</xsl:if>
		</xsl:variable>
		<span class="inputWrapper">
			<xsl:choose>
				<xsl:when test="type = 'textarea'">
					<textarea id="{$name}" name="{$name}" class="{$class}" rows="4" cols="8">
						<xsl:value-of select="value"/>
					</textarea>
				</xsl:when>
				<xsl:otherwise>
					<input id="{$name}" name="{$name}" type="{type}" class="{$class}"
						value="{value}" />
				</xsl:otherwise>
			</xsl:choose>

			<xsl:apply-templates select="Validations" mode="errorMessageAnchor" >
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
			<xsl:apply-templates select="Validations" mode="script">
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
		</span>
	</xsl:template>

	<xsl:template match="FormField_Selection" mode="form">
		<xsl:variable name="name" select="formlib:getValidName(string(name))"/>
		<xsl:variable name="value" select="value"/>
		<xsl:variable name="class">
			<xsl:value-of select="type"/>
			<xsl:if test="string(className)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="className"/>
			</xsl:if>
		</xsl:variable>
		<span class="inputWrapper">
			<xsl:choose>
				<xsl:when test="type = 'radio'">
					<fieldset class="radio">
						<!-- render choices -->
						<xsl:apply-templates select="*[@Name='OptionsProvider']" mode="radio">
							<xsl:with-param name="fieldName" select="$name" />
							<xsl:with-param name="fieldValue" select="$value" />
						</xsl:apply-templates>
					</fieldset>
				</xsl:when>
				<xsl:otherwise>
					<select id="{$name}" name="{$name}" class="{$class}" >
						<xsl:if test="type = 'multi-select'">
							<xsl:attribute name="multiple">multiple</xsl:attribute>
						</xsl:if>
						<xsl:if test="type != 'multi-select'">
							<option></option>
						</xsl:if>
						<!-- render choices -->
						<xsl:apply-templates select="*[@Name='OptionsProvider']" mode="select">
							<xsl:with-param name="fieldValue" select="$value" />
						</xsl:apply-templates>
					</select>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="Validations" mode="errorMessageAnchor" >
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
			<xsl:apply-templates select="Validations" mode="script">
				<xsl:with-param name="fieldName" select="$name" />
			</xsl:apply-templates>
		</span>
	</xsl:template>

	<xsl:template match="FormField_ChoicesProvider[@Name='OptionsProvider']" mode="select">
		<xsl:param name="fieldValue" />
		<xsl:for-each select="FormFieldChoice">
			<xsl:if test="normalize-space(Label) or normalize-space(Value)">
				<option>
					<xsl:if test="$fieldValue = Value">
						<xsl:attribute name="selected">selected</xsl:attribute>
					</xsl:if>
					<xsl:attribute name="value">
						<xsl:apply-templates select="Value"/>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test="string(Label)">
							<xsl:value-of select="Label"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Value"/>
						</xsl:otherwise>
					</xsl:choose>
				</option>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="FormField_ChoicesProvider[@Name='OptionsProvider']" mode="radio">
		<xsl:param name="fieldName" />
		<xsl:param name="fieldValue" />
		<xsl:param name="fieldClass" />
		<xsl:for-each select="FormFieldChoice">
			<xsl:if test="normalize-space(Label) or normalize-space(Value)">
				<label for="{formlib:getValidName(string(Value))}" class="label">
					<input type="radio" id="{formlib:getValidName(string(Value))}" class="{$fieldClass} radio" name="{formlib:getValidName(string(ancestor::FormBuilder_Input[1]/name))}">
						<xsl:attribute name="value">
							<xsl:apply-templates select="Value"/>
						</xsl:attribute>
					</input>
					<xsl:choose>
						<xsl:when test="string(Label)">
							<xsl:value-of select="Label"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Value"/>
						</xsl:otherwise>
					</xsl:choose>
				</label>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="FormField_Captcha" mode="form">
		<span class="inputWrapper">
			<div id="{@COMPUID}"></div>
			<script type="text/javascript"
				src="http://www.google.com/recaptcha/api/challenge?k={Key}">
			</script>
			<noscript>
				<iframe src="http://www.google.com/recaptcha/api/noscript?k={Key}" height="300" width="500" frameborder="0"></iframe><br/>
				<textarea name="recaptcha_challenge_field" rows="3" cols="40"></textarea>
				<input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>&#160;
			</noscript>
			<div style="color:red;display:none;" id="CaptchaError" >&#160;&#160;Please fill out the CAPTCHA</div>
			<div class="clear">&#160;</div>
		</span>
	</xsl:template>

	<xsl:template match="FormBuilder_Form" mode="additionalContent" priority="-3">
		<!-- override this -->
	</xsl:template>




	<xsl:template match="Page[@Schema = 'FormBuilder_Choice']" mode="radio">
		<xsl:param name="class"/>
		<label for="{formlib:getValidName(string(@name))}" class="label">
			<input type="radio" id="{formlib:getValidName(string(@name))}" class="{$class} radio" name="{formlib:getValidName(string(ancestor::FormBuilder_Input[1]/name))}">
				<xsl:attribute name="value">
					<xsl:apply-templates select="@value"/>
				</xsl:attribute>
			</input>
			<xsl:value-of select="@name"/>
		</label>
	</xsl:template>

	<xsl:template match="Page[@Schema = 'FormBuilder_Choice']" mode="select">
		<xsl:param name="eltName" select="../../name"/>
		<xsl:if test="normalize-space(@name)">
			<option>
				<xsl:if test="$postGet/*[local-name() = $eltName] = @value">
					<xsl:attribute name="selected">selected</xsl:attribute>
				</xsl:if>
				<xsl:attribute name="value">
					<xsl:apply-templates select="@value"/>
				</xsl:attribute>
				<xsl:value-of select="@name"/>
			</option>
		</xsl:if>
	</xsl:template>

	<xsl:template match="Record" mode="radio">
		<xsl:param name="class"/>
		<label for="{formlib:getValidName(string(Name))}" class="label">
			<input type="radio" id="{formlib:getValidName(string(Name))}" class="{$class} radio" name="{formlib:getValidName(string(ancestor::FormBuilder_Input[1]/name))}" value="{Value}"/>
			<xsl:value-of select="Name"/>
		</label>
	</xsl:template>

	<xsl:template match="Record" mode="select">
		<xsl:param name="eltName" select="../../name"/>
		<xsl:if test="normalize-space(Name)">
			<option value="{Value}">
				<xsl:if test="$postGet/*[local-name() = $eltName] = Value">
					<xsl:attribute name="selected">selected</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="Name"/>
			</option>
		</xsl:if>
	</xsl:template>

	<xsl:template match="Validations" mode="errorMessageAnchor">
		<xsl:param name="fieldName" />
		<xsl:if test="string($fieldName)">
			<label for="{formlib:getValidName(string($fieldName))}" class="error" style="display:none;">
			</label>
		</xsl:if>
	</xsl:template>

	<xsl:template match="Validations/*[@ValidationName]" mode="errorMessage">
		<xsl:param name="fieldName" />
		<xsl:value-of select="@ValidationName"/>
		<xsl:text>: "</xsl:text>
		<xsl:value-of select="ErrorMessage" />
		<xsl:if test="@ValidationName = 'range' or @ValidationName = 'rangelength'">
			<xsl:if test="string(min)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="minLabel"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="min"/>
			</xsl:if>
			<xsl:if test="string(max)">
				<xsl:text> </xsl:text>
				<xsl:value-of select="maxLabel"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="max"/>
			</xsl:if>
		</xsl:if>
		<xsl:text>"</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>

	<xsl:template name="validationRules">
		<xsl:param name="fields" 	/>
	</xsl:template>

	<xsl:template match="Validations" mode="script">
		<!--<xsl:param name="fieldName" />
		<xsl:variable name="validationTypes" select="*[@ValidationName]"/>    
		<xsl:if test="count($validationTypes) &gt; 0">
			<script type="text/javascript" src="prebuilt/visual_form/jquery/jquery.validate.min.js">
				<xsl:comment>
					&#160;
					<xsl:text>$(document).ready(function(){ </xsl:text>
					&#160;
					<xsl:text>$("#</xsl:text>
					--><!--<xsl:value-of select="$formName" />--><!--
					<xsl:text>").validate({rules:{</xsl:text>
          <xsl:value-of select="$fieldName" />
          <xsl:text>: {</xsl:text>
					<xsl:for-each select="$validationTypes">                        
						<xsl:variable name="validationName" select="@ValidationName" />
						<xsl:variable name="min" select="min"/>
						<xsl:variable name="max" select="max"/>
						<xsl:choose>
							<xsl:when test="string($max) and not(string($min))">
								<xsl:value-of select="concat('max:', $max)"/>
							</xsl:when>
							<xsl:when test="string($min) and not(string($max))">
								<xsl:value-of select="concat('min:', $min)"/>
							</xsl:when>
							<xsl:when test="string($min) and string($max)">
								<xsl:value-of select="concat($validationName, ':[', $min, ',', $max, ']')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$validationName"/>
								<xsl:text>:true</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
            <xsl:if test="position() != last()">,</xsl:if>
					</xsl:for-each>
					<xsl:text>}}, messages: {</xsl:text>
					<xsl:apply-templates select="$validationTypes"  mode="errorMessage" />
					<xsl:text>}</xsl:text>
					&#160;
					<xsl:text>});});</xsl:text>
					&#160;
					<xsl:text>//</xsl:text>
				</xsl:comment>
				&#160;
			</script>
		</xsl:if>-->
	</xsl:template>

</xsl:stylesheet>
