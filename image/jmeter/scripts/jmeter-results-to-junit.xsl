<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>
	<xsl:key name="byThread" match="sample | httpSample" use="normalize-space(@tn)"/>
	<xsl:param name="jmxFile">UNKNOWN.jmx</xsl:param>

	<xsl:template name="millisecs-to-ISO">
		<xsl:param name="millisecs"/>

		<xsl:param name="JDN" select="floor($millisecs div 86400000) + 2440588"/>
		<xsl:param name="mSec" select="$millisecs mod 86400000"/>

		<xsl:param name="f" select="$JDN + 1401 + floor((floor((4 * $JDN + 274277) div 146097) * 3) div 4) - 38"/>
		<xsl:param name="e" select="4*$f + 3"/>
		<xsl:param name="g" select="floor(($e mod 1461) div 4)"/>
		<xsl:param name="h" select="5*$g + 2"/>

		<xsl:param name="d" select="floor(($h mod 153) div 5 ) + 1"/>
		<xsl:param name="m" select="(floor($h div 153) + 2) mod 12 + 1"/>
		<xsl:param name="y" select="floor($e div 1461) - 4716 + floor((14 - $m) div 12)"/>

		<xsl:param name="H" select="floor($mSec div 3600000)"/>
		<xsl:param name="M" select="floor($mSec mod 3600000 div 60000)"/>
		<xsl:param name="S" select="$mSec mod 60000 div 1000"/>

		<xsl:value-of select="concat($y, format-number($m, '-00'), format-number($d, '-00'))" />
		<xsl:value-of select="concat(format-number($H, 'T00'), format-number($M, ':00'), format-number($S, ':00'))" />
	</xsl:template>

	<!--
		https://jmeter.apache.org/usermanual/listeners.html#attributes
		JMeter Attribute Meanings - If enabled in JMeter

		by          Bytes
		sby         Sent Bytes
		de          Data encoding
		dt          Data type
		ec          Error count (0 or 1, unless multiple samples are aggregated)
		hn          Hostname where the sample was generated
		it          Idle Time = time not spent sampling (milliseconds) (generally 0)
		lb          Label
		lt          Latency = time to initial response (milliseconds) - not all samplers support this
		ct          Connect Time = time to establish the connection (milliseconds) - not all samplers support this
		na          Number of active threads for all thread groups
		ng          Number of active threads in this group
		rc          Response Code (e.g. 200)
		rm          Response Message (e.g. OK)
		s           Success flag (true/false)
		sc          Sample count (1, unless multiple samples are aggregated)
		t           Elapsed time (milliseconds)
		tn          Thread Name
		ts          timeStamp (milliseconds since midnight Jan 1, 1970 UTC)
		varname     Value of the named variable
	 -->

	<xsl:template match="/testResults">
		<testsuites>
			<xsl:attribute name="tests"><xsl:value-of select="count(//sample | //httpSample)"/></xsl:attribute>
			<xsl:attribute name="failures"><xsl:value-of select="count(*[./assertionResult/failure[text() = 'true']])"/></xsl:attribute>
			<xsl:attribute name="time"><xsl:value-of select="format-number(sum(//sample/@t | //httpSample/@t) div 1000, '0.000')"/></xsl:attribute>
			<xsl:for-each select="(//sample | //httpSample)[generate-id() = generate-id(key('byThread', normalize-space(@tn))[1])]">
				<xsl:variable name="grpKey" select="normalize-space(@tn)"/>
				<!-- position inside current for-each -->
				<xsl:variable name="threadIdx" select="position()"/>
				<xsl:variable name="threadName">
					<xsl:choose>
						<xsl:when test="$grpKey != ''"><xsl:value-of select="$grpKey"/></xsl:when>
						<xsl:otherwise>UNNAMED_THREAD_GROUP</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<testsuite>
					<!-- required for Junit xsd - no available in the jmeter result -->
					<xsl:attribute name="id"><xsl:value-of select="$threadIdx"/></xsl:attribute>
					<!-- required for Junit xsd - no available in the jmeter result -->
					<xsl:attribute name="name"><xsl:value-of select="$threadName"/></xsl:attribute>
					<!-- required for Junit xsd - no available in the jmeter result -->
<!--					<xsl:attribute name="package">test</xsl:attribute>-->
					<!-- required for Junit xsd - no available in the jmeter result -->
<!--					<xsl:attribute name="hostname">test</xsl:attribute>-->
					<!-- required for JUnit xsd -->
					<xsl:attribute name="timestamp">
						<xsl:call-template name="millisecs-to-ISO">
							<!-- get timestamp from first test result convert it from epoch to ISO8601 -->
							<xsl:with-param name="millisecs" select="key('byThread', $grpKey)[1]/@ts" />
						</xsl:call-template>
					</xsl:attribute>
					<!-- required for Junit xsd - count of test results -->
					<xsl:attribute name="tests"><xsl:value-of select="count(key('byThread', $grpKey))"/></xsl:attribute>
					<!-- required for Junit xsd - count of test failures -->
					<xsl:attribute name="failures"><xsl:value-of select="count(key('byThread', $grpKey)[./assertionResult/failure[text() = 'true']])"/></xsl:attribute>
					<!-- required for Junit xsd - count of test errors -->
					<xsl:attribute name="errors"><xsl:value-of select="count(key('byThread', $grpKey)[./assertionResult/error[text() = 'true']])"/></xsl:attribute>
					<!-- required for Junit xsd - Time taken (in seconds) to execute all the tests -->
					<xsl:attribute name="time"><xsl:value-of select="format-number(sum(key('byThread', $grpKey)/@t) div 1000, '0.000')"/></xsl:attribute>
					<properties></properties>
					<xsl:for-each select="key('byThread', $grpKey)">
						<!-- position inside current for-each -->
						<xsl:variable name="testIdx" select="position()"/>
						<testcase>
							<xsl:attribute name="classname"><xsl:value-of select="concat($threadName, ' - ', name())"/></xsl:attribute>
							<xsl:attribute name="name"><xsl:value-of select="concat(normalize-space(@lb), ' [', $threadIdx, '-', $testIdx, ']')"/></xsl:attribute>
							<xsl:attribute name="time"><xsl:value-of select="format-number(number(@t) div 1000, '0.000')"/></xsl:attribute>
							<xsl:attribute name="file"><xsl:value-of select="$jmxFile"/></xsl:attribute>

							<properties>
								<property name="Bytes"><xsl:value-of select="@by"/></property>
								<property name="SentBytes"><xsl:value-of select="@sby"/></property>
								<property name="DataEncoding"><xsl:value-of select="@de"/></property>
								<property name="DataType"><xsl:value-of select="@dt"/></property>
								<property name="ErrorCount"><xsl:value-of select="@ec"/></property>
								<property name="Hostname"><xsl:value-of select="@hn"/></property>
								<property name="IdleTime"><xsl:value-of select="@it"/></property>
								<property name="Label"><xsl:value-of select="@lb"/></property>
								<property name="Latency"><xsl:value-of select="@lt"/></property>
								<property name="ConnectTime"><xsl:value-of select="@ct"/></property>
								<property name="ThreadsInAllGroups"><xsl:value-of select="@na"/></property>
								<property name="ThreadsInThisGroup"><xsl:value-of select="@ng"/></property>
								<property name="ResponseCode"><xsl:value-of select="@rc"/></property>
								<property name="ResponseMessage"><xsl:value-of select="@rm"/></property>
								<property name="SuccessFlag"><xsl:value-of select="@s"/></property>
								<property name="SampleCount"><xsl:value-of select="@sc"/></property>
								<property name="ElapsedTime"><xsl:value-of select="@t"/></property>
								<property name="ThreadName"><xsl:value-of select="@tn"/></property>
							</properties>

							<xsl:choose>
								<xsl:when test= "@rm = 'OK'">
									<passed><xsl:value-of select="@rm"/></passed>
								</xsl:when>
								<xsl:when test="@rm = 'PASSED'">
									<passed><xsl:value-of select="@rm"/></passed>
								</xsl:when>
							</xsl:choose>
							<xsl:if test="assertionResult[./failure = 'true']">
								<failure>
									<!-- show only the first failure message (if multiple) as the JUnit schema only supports one faulure node -->
									<xsl:attribute name="message"><xsl:value-of select="assertionResult[./failure = 'true']/failureMessage"/></xsl:attribute>
									<!-- show only the first failure type (if multiple) as the JUnit schema only supports one faulure node -->
									<xsl:attribute name="type"><xsl:value-of select="assertionResult[./failure = 'true']/name"/></xsl:attribute>
									<xsl:if test="responseData">
										<xsl:value-of select="responseData"/>
									</xsl:if>
								</failure>
							</xsl:if>
							<xsl:if test="assertionResult[./error = 'true']">
								<error>
									<!-- show only the first failure message (if multiple) as the JUnit schema only supports one faulure node -->
									<xsl:attribute name="message"><xsl:value-of select="assertionResult[./error = 'true']/failureMessage"/></xsl:attribute>
									<!-- show only the first failure type (if multiple) as the JUnit schema only supports one faulure node -->
									<xsl:attribute name="type"><xsl:value-of select="assertionResult[./error = 'true']/name"/></xsl:attribute>
									<xsl:if test="responseData">
										<xsl:value-of select="responseData"/>
									</xsl:if>
								</error>
							</xsl:if>
						</testcase>
					</xsl:for-each>
					<!-- required for JUnit xsd -->
					<system-out></system-out>
					<!-- required for JUnit xsd -->
					<system-err></system-err>
				</testsuite>
			</xsl:for-each>
		</testsuites>
	</xsl:template>
</xsl:stylesheet>