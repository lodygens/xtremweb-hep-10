package xtremweb.communications;
/*
 * Copyrights     : CNRS
 * Author         : Oleg Lodygensky
 * Acknowledgment : XtremWeb-HEP is based on XtremWeb 1.8.0 by inria : http://www.xtremweb.net/
 * Web            : http://www.xtremweb-hep.org
 * 
 *      This file is part of XtremWeb-HEP.
 *
 *    XtremWeb-HEP is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    XtremWeb-HEP is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with XtremWeb-HEP.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import java.io.IOException;

import org.junit.Test;

import xtremweb.communications.XMLRPCCommandSendApp;




/**
 * This tests XML serialization
 * 
 * Created: 23 novembre 2017
 * 
 * @author Oleg Lodygensky
 * @since 11.5.0
 */

public class XMLRPCCommandSendAppTest extends XMLRPCCommandTest {

	public XMLRPCCommandSendAppTest() {
		try {
			setCmd(new XMLRPCCommandSendApp());
			setCmd2(new XMLRPCCommandSendApp());
		} catch (final IOException e) {
		}
	}

	@Override
	@Test
	public void start() {
		super.start();
	}
}
